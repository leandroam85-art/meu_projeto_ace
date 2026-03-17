from django.urls import path
from . import views

urlpatterns = [
    path('', views.dashboard_supervisor, name='dashboard'),
    path('api/login/', views.login_personalizado, name='api_login'),
    
    path('api/imoveis/', views.api_imoveis, name='api_imoveis'),
    path('api/imoveis/<int:pk>/', views.api_imoveis, name='api_imoveis_detail'),
    
    path('api/visitas/', views.api_visitas, name='api_visitas'),
    path('api/visitas/<int:pk>/', views.api_visitas, name='api_visitas_detail'),
    
    # ROTA NOVA PARA RECEBER OS CÃES E GATOS
    path('api/vacinacao/', views.api_vacinacao, name='api_vacinacao'),
]