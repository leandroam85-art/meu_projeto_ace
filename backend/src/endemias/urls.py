from django.contrib import admin
from django.urls import path, include
from endemias import views

urlpatterns = [
    path('', views.dashboard_supervisor, name='dashboard'),
    path('admin/', admin.site.urls),
    path('api/', include('endemias.urls')),
]