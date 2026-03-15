from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # Dashboard principal
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # Administração
    path('admin/', admin.site.urls),
    
    # API do Aplicativo
    path('api/', include('endemias.urls')),
]