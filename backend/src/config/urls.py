from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Rota principal (Dashboard do Supervisor)
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Rota do Painel de Administração
    path('admin/', admin.site.urls),
    
    # Rotas da API para o Celular
    path('api/', include('endemias.urls')),
    
    # ESTA LINHA É A CHAVE: Registra o motor de tradução e mata o erro de NoReverseMatch
    path('i18n/', include('django.conf.urls.i18n')),
]