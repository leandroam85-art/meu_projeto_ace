from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Rota principal (Dashboard)
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Rota do Painel Admin
    path('admin/', admin.site.urls),
    
    # Rotas da API para o Celular
    path('api/', include('endemias.urls')),
]