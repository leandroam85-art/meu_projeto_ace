from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Dashboard principal de Vila Rica
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Administração (Sem o i18n para não gerar erro de namespace)
    path('admin/', admin.site.urls),
    
    # API para o Aplicativo
    path('api/', include('endemias.urls')),
]