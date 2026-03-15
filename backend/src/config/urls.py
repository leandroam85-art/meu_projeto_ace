from django.contrib import admin
from django.urls import path, include
from rest_framework.authtoken import views # <--- IMPORTA O GERADOR DE TOKENS

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('endemias.urls')),
    
    # Rota que o aplicativo vai usar para validar a senha e pegar o Crachá (Token):
    path('api/login/', views.obtain_auth_token), 
]