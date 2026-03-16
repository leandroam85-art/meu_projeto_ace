from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from . import views

urlpatterns = [
    # A PORTA DE ENTRADA DO APLICATIVO: 
    # Recebe usuário e senha e devolve o Token de segurança
    path('login/', obtain_auth_token, name='api_login'),
    
    # (No futuro, colocaremos aqui a rota que recebe os focos de dengue)
    # path('visitas/', views.receber_visita, name='receber_visita'),
]