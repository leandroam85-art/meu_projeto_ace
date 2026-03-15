from django.contrib import admin
from django.urls import path, include, re_path
from endemias import views
from django.views.generic import RedirectView

urlpatterns = [
    # Rota principal (Dashboard do Gestor de Vila Rica)
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Rota do Painel de Administração
    path('admin/', admin.site.urls),
    
    # Rotas da API para o Celular dos Agentes
    path('api/', include('endemias.urls')),
    
    # CORREÇÃO DEFINITIVA: Se o sistema tentar redirecionar para 'pt-br/', 
    # este comando captura e joga o usuário de volta para o admin.
    re_path(r'^pt-br/', RedirectView.as_view(url='/admin/', permanent=False)),
]