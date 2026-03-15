from django.contrib.gis import admin
from .models import Agente, Imovel, Visita

# Registrando Agentes
admin.site.register(Agente, admin.ModelAdmin)

# Registrando Imóveis com o Mapa Interativo do PostGIS!
admin.site.register(Imovel, admin.GISModelAdmin)

# Registrando Visitas
admin.site.register(Visita, admin.ModelAdmin)