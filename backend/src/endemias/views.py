import json
from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from .models import Visita, Agente

@login_required(login_url='/admin/login/')
def dashboard_supervisor(request):
    total_visitas = Visita.objects.count()
    agentes_ativos = Agente.objects.count()

    # --- CORREÇÃO AQUI ---
    # Em vez de 'foco_encontrado', usamos 'amostras_coletadas__gt=0' (gt significa Greater Than / Maior Que)
    # Ou seja: conta todas as visitas onde o número de amostras coletadas for maior que zero.
    focos_dengue = Visita.objects.filter(amostras_coletadas__gt=0).count()
    visitas_com_foco = Visita.objects.filter(amostras_coletadas__gt=0)
    
    marcadores = []

    for visita in visitas_com_foco:
        try:
            # Tenta pegar a latitude e longitude do imóvel visitado
            lat = visita.imovel.latitude 
            lng = visita.imovel.longitude
            
            marcadores.append({
                'lat': float(lat),
                'lng': float(lng),
                'descricao': f"Amostras coletadas: {visita.amostras_coletadas} <br>Data: {visita.data_visita}"
            })
        except Exception:
            # Se o imóvel não tiver coordenada cadastrada, ele simplesmente ignora e não quebra o site
            continue

    # Transforma os pontos em JSON para o mapa ler
    marcadores_json = json.dumps(marcadores)

    contexto = {
        'total_visitas': total_visitas,
        'focos_dengue': focos_dengue,
        'agentes_ativos': agentes_ativos,
        'marcadores_json': marcadores_json,
    }

    return render(request, 'dashboard.html', contexto)