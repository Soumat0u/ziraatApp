from django.utils import timezone
from django.db.models import Sum, Q
from django.shortcuts import render
from django.http import HttpResponse
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from decimal import Decimal
import urllib.parse
from .models import CustomerProfile, SellerProfile, Debt, DebtItem, Medicine, SellerInventory
from .serializers import DebtSerializer, DebtCreateSerializer
from .auth_views import _get_profile_from_token


# ─── Borç Listesi ────────────────────────────────────────────────────
@api_view(['GET'])
def debt_list(request):
    """
    Kullanıcının borçlarını listeler.
    Satıcı ise: verdiği veresiyeler (alacaklar)
    Müşteri ise: aldığı veresiyeler (borçlar)
    Opsiyonel query param: ?status=ACTIVE,PENDING_CUSTOMER
    """
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type == 'SELLER':
        debts = Debt.objects.filter(seller=profile)
    else:
        debts = Debt.objects.filter(customer=profile)

    # Opsiyonel status filtresi
    status_filter = request.query_params.get('status', '')
    if status_filter:
        statuses = [s.strip().upper() for s in status_filter.split(',')]
        debts = debts.filter(status__in=statuses)

    serializer = DebtSerializer(debts, many=True)
    return Response(serializer.data)


# ─── Borç Oluşturma (Sadece Satıcı) ─────────────────────────────────
@api_view(['POST'])
def debt_create(request):
    """
    Satıcı yeni borç oluşturur.
    Body: { customer_phone, amount, due_date, description }
    Müşteriyi telefon numarasıyla bulur.
    """
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type != 'SELLER':
        return Response(
            {'error': 'Bu işlem sadece satıcılar için geçerlidir.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    serializer = DebtCreateSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    # Vade tarihi geçmiş olamaz kontrolü
    due_date = data['due_date']
    if due_date < timezone.now().date():
        return Response(
            {'error': 'Geçmiş bir tarihe borç eklenemez.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Müşteriyi telefon numarasıyla bul
    customer_identifier = data['customer_identifier']
    phone_clean = "".join(c for c in customer_identifier if c.isdigit())
    
    customer = None
    if phone_clean:
        # Son 10 haneye göre veya tam eşleşmeye göre ara (örneğin +90555... ile 0555... eşleşsin)
        last_10 = phone_clean[-10:] if len(phone_clean) >= 10 else phone_clean
        customer = CustomerProfile.objects.filter(
            Q(phone_number__icontains=last_10) | Q(phone_number=customer_identifier)
        ).first()
    else:
        customer = CustomerProfile.objects.filter(phone_number=customer_identifier).first()

    if not customer:
        return Response(
            {'error': 'Bu telefon numarasına ait kayıtlı bir müşteri bulunamadı. Lütfen müşterinin uygulamaya kayıtlı olduğundan emin olun.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    items_data = data.get('items', [])
    if not items_data:
        return Response({'error': 'En az bir kalem (ilaç veya ek ücret) eklemelisiniz.'}, status=status.HTTP_400_BAD_REQUEST)

    total_amount = Decimal('0.00')
    debt_items_to_create = []

    # Calculate total requested quantity per medicine
    requested_medicine_quantities = {}
    for item_data in items_data:
        medicine_id = item_data.get('medicine_id')
        if medicine_id:
            requested_medicine_quantities[medicine_id] = requested_medicine_quantities.get(medicine_id, 0) + item_data['quantity']

    for medicine_id, total_qty in requested_medicine_quantities.items():
        try:
            inv = SellerInventory.objects.get(seller=profile, medicine_id=medicine_id)
            if total_qty > inv.stock_quantity:
                return Response(
                    {'error': f'{inv.medicine.name} için yeterli stok yok. Mevcut stok: {inv.stock_quantity}, İstenen: {total_qty}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except SellerInventory.DoesNotExist:
            return Response({'error': 'Seçilen bir ilaç envanterinizde bulunamadı.'}, status=status.HTTP_400_BAD_REQUEST)

    for item_data in items_data:
        medicine_id = item_data.get('medicine_id')
        name = item_data['name']
        quantity = item_data['quantity']
        price = item_data.get('price')

        medicine = None
        if medicine_id:
            try:
                medicine = Medicine.objects.get(id=medicine_id)
                inv = SellerInventory.objects.get(seller=profile, medicine=medicine)
                price = inv.price
            except (Medicine.DoesNotExist, SellerInventory.DoesNotExist):
                return Response({'error': f'{name} adlı ilaç envanterinizde bulunamadı.'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            if price is None:
                return Response({'error': f'{name} için fiyat belirtilmelidir.'}, status=status.HTTP_400_BAD_REQUEST)

        price = Decimal(str(price))
        item_total = price * quantity
        total_amount += item_total

        debt_items_to_create.append({
            'medicine': medicine,
            'name': name,
            'quantity': quantity,
            'price': price,
            'total_price': item_total
        })

    # Borç oluştur
    debt = Debt.objects.create(
        seller=profile,
        customer=customer,
        amount=total_amount,
        due_date=data['due_date'],
        description=data.get('description', ''),
        status='PENDING_CUSTOMER',
    )

    for di in debt_items_to_create:
        DebtItem.objects.create(
            debt=debt,
            medicine=di['medicine'],
            name=di['name'],
            quantity=di['quantity'],
            price=di['price'],
            total_price=di['total_price']
        )

    result = DebtSerializer(debt).data

    # WhatsApp Linki oluştur
    approve_url = request.build_absolute_uri(f'/api/debts/approve-link/{debt.approval_token}/')
    wa_text = f"Merhaba {customer.first_name}, Ziraat App üzerinden adınıza {total_amount} TL tutarında veresiye oluşturulmuştur. Lütfen linke tıklayarak borcu onaylayın: {approve_url}"
    
    if customer.phone_number:
        phone = customer.phone_number.replace('+', '').replace(' ', '')
        result['whatsapp_link'] = f"https://wa.me/{phone}?text={urllib.parse.quote(wa_text)}"
    else:
        result['whatsapp_link'] = ''

    return Response(result, status=status.HTTP_201_CREATED)


def _deduct_debt_stock(debt):
    for item in debt.items.filter(medicine__isnull=False):
        try:
            inv = SellerInventory.objects.get(seller=debt.seller, medicine=item.medicine)
            inv.stock_quantity = max(0, inv.stock_quantity - item.quantity)
            inv.save()
        except SellerInventory.DoesNotExist:
            pass


def debt_approval_page(request, token):
    try:
        debt = Debt.objects.get(approval_token=token)
    except Debt.DoesNotExist:
        return HttpResponse("<h1>Hata</h1><p>Geçersiz veya süresi dolmuş bağlantı.</p>", status=404)
        
    if request.method == 'POST':
        if debt.status == 'PENDING_CUSTOMER':
            debt.status = 'ACTIVE'
            debt.customer_confirmed_at = timezone.now()
            debt.save()
            _deduct_debt_stock(debt)
            return HttpResponse(
                "<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'></head>"
                "<body style='font-family: sans-serif; text-align: center; padding: 40px;'>"
                "<h1 style='color: #2e7d32;'>Başarılı</h1>"
                "<p>Borcunuz başarıyla onaylandı. Ziraat App üzerinden takip edebilirsiniz.</p>"
                "</body></html>"
            )
        return HttpResponse("<h1>Hata</h1><p>Bu borç zaten işlem görmüş.</p>")
        
    return render(request, 'debt_approval.html', {'debt': debt})


# ─── Borç Onaylama (Sadece Müşteri) ─────────────────────────────────
@api_view(['POST'])
def debt_approve(request, debt_id):
    """Müşteri borcu onaylar → status: ACTIVE"""
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type != 'CUSTOMER':
        return Response(
            {'error': 'Bu işlem sadece müşteriler için geçerlidir.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        debt = Debt.objects.get(pk=debt_id, customer=profile)
    except Debt.DoesNotExist:
        return Response(
            {'error': 'Borç bulunamadı.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if debt.status != 'PENDING_CUSTOMER':
        return Response(
            {'error': 'Bu borç zaten onaylanmış veya reddedilmiş.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    debt.status = 'ACTIVE'
    debt.customer_confirmed_at = timezone.now()
    debt.save()
    _deduct_debt_stock(debt)

    result = DebtSerializer(debt).data
    return Response(result)


# ─── Borç Reddetme (Sadece Müşteri) ─────────────────────────────────
@api_view(['POST'])
def debt_reject(request, debt_id):
    """Müşteri borcu reddeder → status: REJECTED"""
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type != 'CUSTOMER':
        return Response(
            {'error': 'Bu işlem sadece müşteriler için geçerlidir.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        debt = Debt.objects.get(pk=debt_id, customer=profile)
    except Debt.DoesNotExist:
        return Response(
            {'error': 'Borç bulunamadı.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if debt.status != 'PENDING_CUSTOMER':
        return Response(
            {'error': 'Bu borç zaten onaylanmış veya reddedilmiş.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    debt.status = 'REJECTED'
    debt.save()

    result = DebtSerializer(debt).data
    return Response(result)


# ─── Borç Ödendi İşaretleme (Sadece Satıcı) ─────────────────────────
@api_view(['POST'])
def debt_mark_paid(request, debt_id):
    """Satıcı borcu ödendi olarak işaretler → status: PAID"""
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type != 'SELLER':
        return Response(
            {'error': 'Bu işlem sadece satıcılar için geçerlidir.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    try:
        debt = Debt.objects.get(pk=debt_id, seller=profile)
    except Debt.DoesNotExist:
        return Response(
            {'error': 'Borç bulunamadı.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if debt.status != 'ACTIVE':
        return Response(
            {'error': 'Sadece aktif borçlar ödendi olarak işaretlenebilir.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    debt.status = 'PAID'
    debt.save()

    result = DebtSerializer(debt).data
    return Response(result)


# ─── Borç Özeti ──────────────────────────────────────────────────────
@api_view(['GET'])
def debt_summary(request):
    """
    Kullanıcının borç özetini döndürür.
    Satıcı: toplam alacak, aktif borç sayısı, bekleyen onay sayısı
    Müşteri: toplam borç, aktif borç sayısı, bekleyen onay sayısı
    """
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type == 'SELLER':
        debts = Debt.objects.filter(seller=profile)
    else:
        debts = Debt.objects.filter(customer=profile)

    total_active = debts.filter(status='ACTIVE').aggregate(
        total=Sum('amount')
    )['total'] or 0

    total_paid = debts.filter(status='PAID').aggregate(
        total=Sum('amount')
    )['total'] or 0

    active_count = debts.filter(status='ACTIVE').count()
    pending_count = debts.filter(status='PENDING_CUSTOMER').count()
    paid_count = debts.filter(status='PAID').count()
    rejected_count = debts.filter(status='REJECTED').count()

    return Response({
        'total_active_amount': str(total_active),
        'total_paid_amount': str(total_paid),
        'active_count': active_count,
        'pending_count': pending_count,
        'paid_count': paid_count,
        'rejected_count': rejected_count,
    })


# ─── Müşteri Arama (Telefon Numarası) ───────────────────────────────
@api_view(['GET'])
def customer_search(request):
    """
    Satıcı müşteri ararken kullanır.
    Query param: ?phone=05xx
    """
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type != 'SELLER':
        return Response(
            {'error': 'Bu işlem sadece satıcılar için geçerlidir.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    phone = request.query_params.get('phone', '').strip()
    if not phone:
        return Response(
            {'error': 'Telefon numarası gerekli.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    customers = CustomerProfile.objects.filter(
        phone_number__icontains=phone
    )[:10]

    results = []
    for c in customers:
        results.append({
            'id': c.id,
            'account_id': c.account_id,
            'full_name': c.full_name,
            'phone_number': c.phone_number,
        })

    return Response(results)
