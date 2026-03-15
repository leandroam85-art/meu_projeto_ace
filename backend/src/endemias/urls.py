from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # 1. Rota principal: Abre o Dashboard do Supervisor
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # 2. Rota do Painel Admin
    path('admin/', admin.site.urls),
    
    # 3. Rotas do Aplicativo (Celular)
    path('api/', include('endemias.urls')),
]