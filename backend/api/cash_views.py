from decimal import Decimal
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import CashRegister, CashTransaction
from .auth_views import _get_profile_from_token


@api_view(['GET'])
def cash_register_detail(request):
    """
    Satıcının bağlı olduğu firmanın kasa bilgilerini döndürür.
    Bakiye, firma adı, gizli kod ve çalışan bilgileri.
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

    if not profile.company:
        return Response(
            {'error': 'Bir firmaya bağlı değilsiniz.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        cash_register = CashRegister.objects.get(company=profile.company)
    except CashRegister.DoesNotExist:
        # Firma var ama kasa oluşturulmamış — oluştur
        cash_register = CashRegister.objects.create(company=profile.company)

    # Firma çalışanları
    employees = profile.company.employees.all()
    employee_list = [
        {
            'id': emp.id,
            'full_name': emp.full_name,
            'is_owner': emp.is_owner,
        }
        for emp in employees
    ]

    # Patron olan hesap tüm kasayı, çalışanlar ise yalnızca kendi işlemlerinin bakiyesini görür
    if profile.is_owner:
        balance = cash_register.balance
    else:
        from django.db.models import Sum
        income_sum = CashTransaction.objects.filter(
            cash_register=cash_register,
            employee=profile,
            transaction_type='INCOME'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        expense_sum = CashTransaction.objects.filter(
            cash_register=cash_register,
            employee=profile,
            transaction_type='EXPENSE'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        balance = income_sum - expense_sum

    return Response({
        'balance': str(balance),
        'company_name': profile.company.name,
        'secret_code': profile.company.secret_code if profile.is_owner else '',
        'is_owner': profile.is_owner,
        'employee_count': len(employee_list),
        'employees': employee_list if profile.is_owner else [],
        'updated_at': cash_register.updated_at.isoformat() if cash_register.updated_at else None,
    })


@api_view(['GET'])
def cash_transactions_list(request):
    """
    Kasa hareketlerini listeler.
    Opsiyonel query param: ?type=INCOME veya ?type=EXPENSE
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

    if not profile.company:
        return Response(
            {'error': 'Bir firmaya bağlı değilsiniz.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        cash_register = CashRegister.objects.get(company=profile.company)
    except CashRegister.DoesNotExist:
        return Response([])

    # Patron olan hesap tüm kasa hareketlerini, çalışanlar yalnızca kendi hareketlerini görür
    if profile.is_owner:
        transactions = CashTransaction.objects.filter(cash_register=cash_register)
    else:
        transactions = CashTransaction.objects.filter(cash_register=cash_register, employee=profile)

    # Opsiyonel tip filtresi
    type_filter = request.query_params.get('type', '').upper()
    if type_filter in ('INCOME', 'EXPENSE'):
        transactions = transactions.filter(transaction_type=type_filter)

    result = []
    for t in transactions[:100]:  # Son 100 işlem
        result.append({
            'id': t.id,
            'transaction_type': t.transaction_type,
            'type_display': 'Gelir' if t.transaction_type == 'INCOME' else 'Gider',
            'amount': str(t.amount),
            'description': t.description,
            'employee_name': t.employee.full_name if t.employee else 'Bilinmeyen',
            'employee_id': t.employee.id if t.employee else None,
            'created_at': t.created_at.isoformat(),
        })

    return Response(result)


@api_view(['POST'])
def cash_add_transaction(request):
    """
    Kasaya yeni gelir veya gider ekler.
    Body: { "type": "INCOME"|"EXPENSE", "amount": "100.00", "description": "Açıklama" }
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

    if not profile.company:
        return Response(
            {'error': 'Bir firmaya bağlı değilsiniz.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    transaction_type = request.data.get('type', '').upper()
    if transaction_type not in ('INCOME', 'EXPENSE'):
        return Response(
            {'error': 'Geçersiz işlem türü. "INCOME" veya "EXPENSE" olmalı.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        amount = Decimal(str(request.data.get('amount', '0')))
        if amount <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        return Response(
            {'error': 'Geçerli bir tutar giriniz (0\'dan büyük olmalı).'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    description = request.data.get('description', '').strip()
    if not description:
        return Response(
            {'error': 'Açıklama zorunludur.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        cash_register = CashRegister.objects.get(company=profile.company)
    except CashRegister.DoesNotExist:
        cash_register = CashRegister.objects.create(company=profile.company)

    # İşlem oluştur
    transaction = CashTransaction.objects.create(
        cash_register=cash_register,
        employee=profile,
        transaction_type=transaction_type,
        amount=amount,
        description=description,
    )

    # Bakiyeyi güncelle
    if transaction_type == 'INCOME':
        cash_register.balance += amount
    else:
        cash_register.balance -= amount
    cash_register.save()

    return Response({
        'id': transaction.id,
        'transaction_type': transaction.transaction_type,
        'type_display': 'Gelir' if transaction_type == 'INCOME' else 'Gider',
        'amount': str(transaction.amount),
        'description': transaction.description,
        'employee_name': profile.full_name,
        'created_at': transaction.created_at.isoformat(),
        'new_balance': str(cash_register.balance),
    }, status=status.HTTP_201_CREATED)
