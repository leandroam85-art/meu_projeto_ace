from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # Painel de Administração Padrão do Django
    path('admin/', admin.site.urls),
    
    # Repassa TUDO (Dashboard e API) para as rotas do app endemias
    path('', include('endemias.urls')),
]