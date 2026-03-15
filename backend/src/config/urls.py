from django.urls import path
from . import views

urlpatterns = [
    path('imoveis/', views.lista_imoveis, name='imoveis'),
]