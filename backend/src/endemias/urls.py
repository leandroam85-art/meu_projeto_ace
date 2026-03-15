from django.contrib import admin
from django.urls import path, include
from endemias import views  # <-- 1. Importamos as regras que acabamos de criar!

urlpatterns = [
    # 2. Agora, o endereço principal do site carrega o Dashboard!
    path('', views.dashboard_supervisor, name='dashboard'), 
    
    path('admin/', admin.site.urls),
    path('api/', include('endemias.urls')),
]