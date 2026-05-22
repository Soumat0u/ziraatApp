from rest_framework import viewsets, permissions, status, filters
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.db.models import Count, Q
from .models import Category, Plant, Medicine, SellerInventory, Notification, SellerProfile
from .serializers import (
    CategorySerializer, PlantSerializer, MedicineSerializer,
    SellerInventorySerializer, InventoryUpdateSerializer, NotificationSerializer,
    StoreListSerializer,
)

class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class PlantViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Plant.objects.all()
    serializer_class = PlantSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category']
    search_fields = ['plant_name', 'disease_name', 'active_ingredient']
    ordering_fields = ['plant_name', 'disease_name']
    ordering = ['plant_name']

class MedicineViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Medicine.objects.all()
    serializer_class = MedicineSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category']
    search_fields = ['name', 'active_ingredient', 'formulation']
    ordering_fields = ['name', 'active_ingredient']
    ordering = ['name']

class SellerInventoryViewSet(viewsets.ModelViewSet):
    serializer_class = SellerInventorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['medicine__category']
    search_fields = ['medicine__name', 'medicine__active_ingredient']
    
    def get_queryset(self):
        from .auth_views import _get_profile_from_token
        queryset = SellerInventory.objects.all()
        profile, account_type = _get_profile_from_token(self.request)
        if profile and account_type == 'SELLER':
            queryset = queryset.filter(seller=profile)
        
        low_stock = self.request.query_params.get('low_stock', None)
        if low_stock and low_stock.lower() == 'true':
            queryset = queryset.filter(stock_quantity__lte=10)
        return queryset

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = InventoryUpdateSerializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        full_serializer = self.get_serializer(instance)
        return Response(full_serializer.data)

    @action(detail=False, methods=['post'], url_path='add-custom')
    def add_custom(self, request):
        from .auth_views import _get_profile_from_token
        from django.shortcuts import get_object_or_404
        profile, account_type = _get_profile_from_token(request)
        if not profile or account_type != 'SELLER':
            return Response({'error': 'Geçersiz yetki.'}, status=status.HTTP_403_FORBIDDEN)
            
        data = request.data
        medicine_id = data.get('medicine_id')
        
        if medicine_id:
            medicine = get_object_or_404(Medicine, pk=medicine_id)
        else:
            name = data.get('name', '').strip()
            if not name:
                return Response({'error': 'İlaç ismi veya ID zorunludur.'}, status=status.HTTP_400_BAD_REQUEST)
                
            category, _ = Category.objects.get_or_create(name='Diğer İlaçlar')
            
            medicine, _ = Medicine.objects.get_or_create(
                name=name,
                defaults={
                    'active_ingredient': data.get('active_ingredient', ''),
                    'formulation': data.get('formulation', ''),
                    'category': category
                }
            )
        
        price = data.get('price', 0)
        stock_quantity = data.get('stock_quantity', 1)
        if not price or str(price).strip() == '': price = 0
        if not stock_quantity or str(stock_quantity).strip() == '': stock_quantity = 1
        
        inventory, created = SellerInventory.objects.get_or_create(
            seller=profile,
            medicine=medicine,
            defaults={
                'price': price,
                'stock_quantity': stock_quantity
            }
        )
        
        if not created:
            inventory.price = price
            inventory.stock_quantity = int(inventory.stock_quantity) + int(stock_quantity)
            inventory.save()
            
        return Response({'message': 'Ürün başarıyla stoğa eklendi.'}, status=status.HTTP_201_CREATED)

class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.all().order_by('-created_at')


# ─── Mağaza (Store) API ──────────────────────────────────────────────
@api_view(['GET'])
def stores_list(request):
    """Tüm satıcı mağazalarını listeler. ?search= ile arama destekli."""
    search = request.query_params.get('search', '').strip()
    queryset = SellerProfile.objects.annotate(
        product_count=Count('sellerinventory')
    )

    if search:
        queryset = queryset.filter(
            Q(company_name__icontains=search) |
            Q(address__icontains=search)
        )

    queryset = queryset.order_by('company_name')
    serializer = StoreListSerializer(queryset, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def store_inventory(request, seller_id):
    """Belirli bir satıcının envanterini döndürür."""
    try:
        seller = SellerProfile.objects.get(pk=seller_id)
    except SellerProfile.DoesNotExist:
        return Response({'error': 'Mağaza bulunamadı.'}, status=status.HTTP_404_NOT_FOUND)

    inventory = SellerInventory.objects.filter(seller=seller).select_related('medicine', 'medicine__category')
    serializer = SellerInventorySerializer(inventory, many=True)
    return Response({
        'store': {
            'id': seller.id,
            'company_name': seller.company_name,
            'phone_number': seller.phone_number or '',
            'address': seller.address,
        },
        'inventory': serializer.data,
    })
