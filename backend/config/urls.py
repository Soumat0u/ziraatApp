from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from api.views import CategoryViewSet, PlantViewSet, MedicineViewSet, SellerInventoryViewSet, NotificationViewSet
from api.ai_views import ai_ask, ai_history, ai_smart_search
from api.auth_views import register_view, login_view, me_view, logout_view

router = DefaultRouter()
router.register(r'categories', CategoryViewSet)
router.register(r'plants', PlantViewSet)
router.register(r'medicines', MedicineViewSet)
router.register(r'inventory', SellerInventoryViewSet, basename='inventory')
router.register(r'notifications', NotificationViewSet, basename='notifications')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    path('api/auth/register/', register_view, name='auth-register'),
    path('api/auth/login/', login_view, name='auth-login'),
    path('api/auth/me/', me_view, name='auth-me'),
    path('api/auth/logout/', logout_view, name='auth-logout'),
    path('api/ai/ask/', ai_ask, name='ai-ask'),
    path('api/ai/history/', ai_history, name='ai-history'),
    path('api/ai/smart-search/', ai_smart_search, name='ai-smart-search'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
