from django.urls import path
from . import views

urlpatterns = [
    # A PORTA DE ENTRADA DO APLICATIVO (Login)
    path('login/', views.login_personalizado, name='api_login'),
    path('login', views.login_personalizado),
    path('api/login/', views.login_personalizado), # Curinga extra por segurança
    
    # --- NOVAS PORTAS (API) PARA O APLICATIVO 👇 ---
    
    # Portas dos Imóveis (Manda a lista de casas e recebe os novos cadastros)
    path('api/imoveis/', views.api_imoveis),
    path('api/imoveis/<int:pk>/', views.api_imoveis),
    path('imoveis/', views.api_imoveis),
    path('imoveis/<int:pk>/', views.api_imoveis),

    # Portas das Visitas e Focos (Manda o histórico e recebe os boletins novos)
    path('api/visitas/', views.api_visitas),
    path('api/visitas/<int:pk>/', views.api_visitas),
    path('visitas/', views.api_visitas),
    path('visitas/<int:pk>/', views.api_visitas),
]