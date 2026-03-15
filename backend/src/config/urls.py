from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    # 1. Rota principal: Dashboard do Supervisor
    path('', views.dashboard_supervisor, name='dashboard'),
    
    # 2. Rota do Painel Admin
    path('admin/', admin.site.urls),
    
    # 3. Rotas da API para o Celular
    path('api/', include('endemias.urls')),
    
    # 4. Rota de Idioma (Evita o erro NoReverseMatch)
    path('i18n/', include('django.conf.urls.i18n')),
]