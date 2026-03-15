from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Rota principal (Dashboard)
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Rota do Painel de Administração
    path('admin/', admin.site.urls),
    
    # Rotas da API para o Celular
    path('api/', include('endemias.urls')),
    
    # ESTA LINHA É OBRIGATÓRIA: Registra o sistema de idiomas para evitar o erro de namespace
    path('i18n/', include('django.conf.urls.i18n')),
]