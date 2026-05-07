from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Category, Product, SellerInventory, Notification
from .serializers import (
    CategorySerializer, ProductSerializer, 
    SellerInventorySerializer, InventoryUpdateSerializer, NotificationSerializer
)

class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class ProductViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

class SellerInventoryViewSet(viewsets.ModelViewSet):
    serializer_class = SellerInventorySerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and user.role == 'SELLER':
            return SellerInventory.objects.filter(seller=user)
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
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')
