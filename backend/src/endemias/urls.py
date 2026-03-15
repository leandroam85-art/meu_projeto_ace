from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AgenteViewSet, ImovelViewSet, VisitaViewSet

router = DefaultRouter()
router.register(r'agentes', AgenteViewSet)
router.register(r'imoveis', ImovelViewSet)
router.register(r'visitas', VisitaViewSet)

urlpatterns = [
    path('', include(router.urls)),
]