from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Rota principal (Abre o Dashboard)
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Rota do Painel de Administração
    path('admin/', admin.site.urls),
    
    # Rotas da API para o Aplicativo do Celular
    path('api/', include('endemias.urls')),
]