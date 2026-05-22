from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from api.views import CategoryViewSet, PlantViewSet, MedicineViewSet, SellerInventoryViewSet, NotificationViewSet, stores_list, store_inventory
from api.ai_views import ai_ask, ai_history, ai_smart_search
from api.auth_views import register_view, login_view, me_view, logout_view
from api.debt_views import (
    debt_list, debt_create, debt_approve, debt_reject,
    debt_mark_paid, debt_summary, customer_search, debt_approval_page
)
from api.cash_views import cash_register_detail, cash_transactions_list, cash_add_transaction
from api.workplace_views import (
    workplace_employees_list, workplace_remove_employee, workplace_employee_transactions
)

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
    # Veresiye (Borç) endpoint'leri
    path('api/debts/', debt_list, name='debt-list'),
    path('api/debts/create/', debt_create, name='debt-create'),
    path('api/debts/summary/', debt_summary, name='debt-summary'),
    path('api/debts/approve-link/<str:token>/', debt_approval_page, name='debt-approve-page'),
    path('api/debts/<int:debt_id>/approve/', debt_approve, name='debt-approve'),
    path('api/debts/<int:debt_id>/reject/', debt_reject, name='debt-reject'),
    path('api/debts/<int:debt_id>/mark-paid/', debt_mark_paid, name='debt-mark-paid'),
    path('api/customers/search/', customer_search, name='customer-search'),
    # Mağaza endpoint'leri
    path('api/stores/', stores_list, name='stores-list'),
    path('api/stores/<int:seller_id>/inventory/', store_inventory, name='store-inventory'),
    # Kasa endpoint'leri
    path('api/cash/', cash_register_detail, name='cash-register'),
    path('api/cash/transactions/', cash_transactions_list, name='cash-transactions'),
    path('api/cash/add/', cash_add_transaction, name='cash-add'),
    # İşyerim (Workplace) endpoint'leri
    path('api/workplace/employees/', workplace_employees_list, name='workplace-employees'),
    path('api/workplace/employees/<int:employee_id>/remove/', workplace_remove_employee, name='workplace-remove-employee'),
    path('api/workplace/employees/<int:employee_id>/transactions/', workplace_employee_transactions, name='workplace-employee-transactions'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
