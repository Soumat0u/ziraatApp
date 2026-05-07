from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from api.views import CategoryViewSet, ProductViewSet, SellerInventoryViewSet, NotificationViewSet
from api.ai_views import ai_ask, ai_history

router = DefaultRouter()
router.register(r'categories', CategoryViewSet)
router.register(r'products', ProductViewSet)
router.register(r'inventory', SellerInventoryViewSet, basename='inventory')
router.register(r'notifications', NotificationViewSet, basename='notifications')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    path('api/ai/ask/', ai_ask, name='ai-ask'),
    path('api/ai/history/', ai_history, name='ai-history'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
