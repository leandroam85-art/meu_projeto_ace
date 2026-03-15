from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('endemias.urls')),
    # Removido o redirecionamento de pt-br para não confundir o resolver
]