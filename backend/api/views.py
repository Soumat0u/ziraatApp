from rest_framework import viewsets, permissions, status, filters
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Category, Plant, Medicine, SellerInventory, Notification
from .serializers import (
    CategorySerializer, PlantSerializer, MedicineSerializer,
    SellerInventorySerializer, InventoryUpdateSerializer, NotificationSerializer
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
        return SellerInventory.objects.all()

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = InventoryUpdateSerializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        full_serializer = self.get_serializer(instance)
        return Response(full_serializer.data)

class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.all().order_by('-created_at')
