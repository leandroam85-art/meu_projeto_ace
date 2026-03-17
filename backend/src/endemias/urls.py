from django.urls import path
from . import views

urlpatterns = [
    # O PAINEL WEB (Dashboard do Supervisor)
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # A PORTA DE ENTRADA DO APLICATIVO (Login)
    path('api/login/', views.login_personalizado, name='api_login'),
    
    # PORTAS DE IMÓVEIS
    path('api/imoveis/', views.api_imoveis, name='api_imoveis'),
    path('api/imoveis/<int:pk>/', views.api_imoveis, name='api_imoveis_detail'),
    
    # PORTAS DE VISITAS (PNCD)
    path('api/visitas/', views.api_visitas, name='api_visitas'),
    path('api/visitas/<int:pk>/', views.api_visitas, name='api_visitas_detail'),
    
    # NOVA PORTA: VACINAÇÃO ANTIRRÁBICA (Zoonose)
    path('api/vacinacao/', views.api_vacinacao, name='api_vacinacao'),
]