from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Dashboard principal
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Painel de Administração
    path('admin/', admin.site.urls),
    
    # API do Celular (chama o arquivo que limpamos no passo 1)
    path('api/', include('endemias.urls')),
]