from django.urls import path
from . import views

urlpatterns = [
    # A PORTA DE ENTRADA DO APLICATIVO (COM BARRA): 
    # Chama a nossa fechadura personalizada que aceita português e inglês!
    path('login/', views.login_personalizado, name='api_login'),
    
    # A PORTA ALTERNATIVA (SEM BARRA): 
    # Para o celular que "engole" a barra no final do link não perder a senha!
    path('login', views.login_personalizado),
    
    # (No futuro, colocaremos aqui a rota que recebe os focos de dengue)
    # path('visitas/', views.receber_visita, name='receber_visita'),
]