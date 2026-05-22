from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import SellerProfile, CashTransaction
from .auth_views import _get_profile_from_token

@api_view(['GET'])
def workplace_employees_list(request):
    """
    Owner (Admin) olan satıcının şirketindeki çalışanları listeler.
    """
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response({'error': 'Geçersiz veya eksik token.'}, status=status.HTTP_401_UNAUTHORIZED)
    
    if account_type != 'SELLER' or not profile.is_owner:
        return Response({'error': 'Bu işlem sadece işyeri sahibi (admin) yetkisindedir.'}, status=status.HTTP_403_FORBIDDEN)
        
    if not profile.company:
        return Response({'error': 'Herhangi bir şirkete bağlı değilsiniz.'}, status=status.HTTP_400_BAD_REQUEST)

    # Şirketteki tüm çalışanlar
    employees = SellerProfile.objects.filter(company=profile.company).order_by('first_name', 'last_name')
    
    result = []
    for emp in employees:
        result.append({
            'id': emp.id,
            'account_id': emp.account_id,
            'full_name': emp.full_name,
            'first_name': emp.first_name,
            'last_name': emp.last_name,
            'email': emp.email,
            'phone_number': emp.phone_number or '',
            'is_owner': emp.is_owner,
            'created_at': emp.created_at.isoformat() if emp.created_at else None,
        })
        
    return Response(result)


@api_view(['POST'])
def workplace_remove_employee(request, employee_id):
    """
    Bir çalışanı şirketten çıkarır (company alanını null yapar, is_owner=False yapar).
    """
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response({'error': 'Geçersiz veya eksik token.'}, status=status.HTTP_401_UNAUTHORIZED)
    
    if account_type != 'SELLER' or not profile.is_owner:
        return Response({'error': 'Bu işlem sadece işyeri sahibi (admin) yetkisindedir.'}, status=status.HTTP_403_FORBIDDEN)
        
    if not profile.company:
        return Response({'error': 'Herhangi bir şirkete bağlı değilsiniz.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        employee = SellerProfile.objects.get(pk=employee_id, company=profile.company)
    except SellerProfile.DoesNotExist:
        return Response({'error': 'Çalışan bulunamadı veya şirketinizde değil.'}, status=status.HTTP_404_NOT_FOUND)

    if employee.id == profile.id:
        return Response({'error': 'Kendinizi şirketten çıkaramazsınız.'}, status=status.HTTP_400_BAD_REQUEST)

    # Çalışanı şirketten çıkar
    employee.company = None
    employee.is_owner = False
    employee.save()

    return Response({'message': f'{employee.full_name} başarıyla şirketten çıkarıldı.'})


@api_view(['GET'])
def workplace_employee_transactions(request, employee_id):
    """
    Bir çalışanın yaptığı kasa girdi-çıktı (gelir/gider) hareketlerini listeler.
    """
    profile, account_type = _get_profile_from_token(request)
    if profile is None:
        return Response({'error': 'Geçersiz veya eksik token.'}, status=status.HTTP_401_UNAUTHORIZED)
    
    if account_type != 'SELLER' or not profile.is_owner:
        return Response({'error': 'Bu işlem sadece işyeri sahibi (admin) yetkisindedir.'}, status=status.HTTP_403_FORBIDDEN)
        
    if not profile.company:
        return Response({'error': 'Herhangi bir şirkete bağlı değilsiniz.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        employee = SellerProfile.objects.get(pk=employee_id, company=profile.company)
    except SellerProfile.DoesNotExist:
        return Response({'error': 'Çalışan bulunamadı veya şirketinizde değil.'}, status=status.HTTP_404_NOT_FOUND)

    # Kasa hareketlerini çek
    transactions = CashTransaction.objects.filter(
        cash_register__company=profile.company,
        employee=employee
    ).order_by('-created_at')
    
    result = []
    for t in transactions:
        result.append({
            'id': t.id,
            'transaction_type': t.transaction_type,
            'type_display': 'Gelir' if t.transaction_type == 'INCOME' else 'Gider',
            'amount': str(t.amount),
            'description': t.description,
            'created_at': t.created_at.isoformat(),
        })
        
    return Response(result)
