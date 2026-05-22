import secrets
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import CustomerProfile, SellerProfile, AuthToken
from .auth_serializers import (
    CustomerRegisterSerializer, SellerRegisterSerializer,
    LoginSerializer, CustomerProfileSerializer, SellerProfileSerializer,
)


def _generate_token():
    """64 karakterlik güvenli rastgele token üretir."""
    return secrets.token_hex(32)


def _create_auth_token(profile, account_type):
    """Bir profil için auth token oluşturur, eskisini siler."""
    AuthToken.objects.filter(
        account_type=account_type,
        profile_id=profile.pk,
    ).delete()

    token = _generate_token()
    AuthToken.objects.create(
        token=token,
        account_type=account_type,
        account_id=profile.account_id,
        profile_id=profile.pk,
    )
    return token


def _get_profile_from_token(request):
    """Authorization header'ından token okuyup profili döndürür."""
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Token '):
        return None, None

    token_str = auth_header.split('Token ', 1)[1].strip()
    try:
        auth_token = AuthToken.objects.get(token=token_str)
    except AuthToken.DoesNotExist:
        return None, None

    if auth_token.account_type == 'CUSTOMER':
        try:
            profile = CustomerProfile.objects.get(pk=auth_token.profile_id)
            return profile, 'CUSTOMER'
        except CustomerProfile.DoesNotExist:
            return None, None
    else:
        try:
            profile = SellerProfile.objects.get(pk=auth_token.profile_id)
            return profile, 'SELLER'
        except SellerProfile.DoesNotExist:
            return None, None


# ─── Kayıt ───────────────────────────────────────────────────────────
@api_view(['POST'])
def register_view(request):
    """
    Yeni hesap kaydı.
    Body: { "account_type": "CUSTOMER"|"SELLER", ...fields }
    """
    account_type = request.data.get('account_type', '').upper()

    if account_type == 'CUSTOMER':
        serializer = CustomerRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        profile = CustomerProfile.objects.create(
            first_name=data['first_name'],
            last_name=data['last_name'],
            email=data['email'],
            phone_number=data.get('phone_number') or None,
            password_hash=data['password'],  # save() methodu hashler
        )
        token = _create_auth_token(profile, 'CUSTOMER')
        profile_data = CustomerProfileSerializer(profile).data

    elif account_type == 'SELLER':
        serializer = SellerRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        company_code = data.get('company_code', '').strip().upper()

        if company_code:
            # Mevcut firmaya katıl
            from .models import Company
            company = Company.objects.get(secret_code=company_code)
            is_owner = False
        else:
            # Yeni firma oluştur
            from .models import Company, CashRegister
            company = Company.objects.create(name=data['company_name'])
            CashRegister.objects.create(company=company)
            is_owner = True

        profile = SellerProfile.objects.create(
            first_name=data['first_name'],
            last_name=data['last_name'],
            email=data['email'],
            phone_number=data.get('phone_number') or None,
            password_hash=data['password'],
            company_name=data['company_name'],
            tax_number=data.get('tax_number', ''),
            address=data.get('address', ''),
            company=company,
            is_owner=is_owner,
        )
        token = _create_auth_token(profile, 'SELLER')
        profile_data = SellerProfileSerializer(profile).data

    else:
        return Response(
            {'error': 'Geçersiz hesap türü. "CUSTOMER" veya "SELLER" olmalı.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    return Response({
        'token': token,
        'account_type': account_type,
        'user': profile_data,
    }, status=status.HTTP_201_CREATED)


# ─── Giriş ───────────────────────────────────────────────────────────
@api_view(['POST'])
def login_view(request):
    """
    Giriş. Önce customers tablosuna bakar, bulamazsa sellers tablosuna bakar.
    Body: { "email": "...", "password": "..." }
    """
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    email = serializer.validated_data['email']
    password = serializer.validated_data['password']

    # Müşteri tablosunu kontrol et
    try:
        customer = CustomerProfile.objects.get(email=email)
        if customer.check_password(password):
            token = _create_auth_token(customer, 'CUSTOMER')
            return Response({
                'token': token,
                'account_type': 'CUSTOMER',
                'user': CustomerProfileSerializer(customer).data,
            })
    except CustomerProfile.DoesNotExist:
        pass

    # Satıcı tablosunu kontrol et
    try:
        seller = SellerProfile.objects.get(email=email)
        if seller.check_password(password):
            token = _create_auth_token(seller, 'SELLER')
            return Response({
                'token': token,
                'account_type': 'SELLER',
                'user': SellerProfileSerializer(seller).data,
            })
    except SellerProfile.DoesNotExist:
        pass

    return Response(
        {'error': 'E-posta veya şifre hatalı.'},
        status=status.HTTP_401_UNAUTHORIZED,
    )


# ─── Profil (Me) ─────────────────────────────────────────────────────
@api_view(['GET'])
def me_view(request):
    """Token ile giriş yapmış kullanıcının profil bilgilerini döndürür."""
    profile, account_type = _get_profile_from_token(request)

    if profile is None:
        return Response(
            {'error': 'Geçersiz veya eksik token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if account_type == 'CUSTOMER':
        data = CustomerProfileSerializer(profile).data
    else:
        data = SellerProfileSerializer(profile).data

    return Response({
        'account_type': account_type,
        'user': data,
    })


# ─── Çıkış ───────────────────────────────────────────────────────────
@api_view(['POST'])
def logout_view(request):
    """Token'ı silerek çıkış yapar."""
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Token '):
        token_str = auth_header.split('Token ', 1)[1].strip()
        AuthToken.objects.filter(token=token_str).delete()

    return Response({'message': 'Çıkış başarılı.'})
