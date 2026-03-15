from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Rota principal do Dashboard
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Rota do Painel Admin
    path('admin/', admin.site.urls),
    
    # Rota das APIs do Aplicativo
    path('api/', include('endemias.urls')),
    
    # ESSA LINHA RESOLVE O ERRO: Registra o motor de tradução
    path('i18n/', include('django.conf.urls.i18n')),
]