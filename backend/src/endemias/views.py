import json
from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from .models import Visita, Agente

@login_required(login_url='/admin/login/')
def dashboard_supervisor(request):
    total_visitas = Visita.objects.count()
    focos_dengue = Visita.objects.filter(foco_encontrado=True).count()
    agentes_ativos = Agente.objects.count()

    # --- INÍCIO DA MÁGICA DO MAPA ---
    # Busca todas as visitas onde foi encontrado foco de dengue
    visitas_com_foco = Visita.objects.filter(foco_encontrado=True)
    marcadores = []

    for visita in visitas_com_foco:
        try:
            # ATENÇÃO LEANDRO: Aqui o Python tenta ler a latitude e longitude.
            # Se os seus campos no banco tiverem nomes diferentes, basta alterar as duas linhas abaixo.
            # (Exemplo: se for PostGIS puro no Imóvel, poderia ser visita.imovel.localizacao.y)
            lat = visita.imovel.latitude 
            lng = visita.imovel.longitude
            
            marcadores.append({
                'lat': float(lat),
                'lng': float(lng),
                'descricao': f"Data da detecção: {visita.data_visita}"
            })
        except Exception:
            # Se o cadastro não tiver coordenada ou der algum erro de nome, ele pula e não quebra o site
            continue

    # Transforma a lista de pontos em um formato JSON que o mapa (JavaScript) consegue ler
    marcadores_json = json.dumps(marcadores)
    # --- FIM DA MÁGICA DO MAPA ---

    contexto = {
        'total_visitas': total_visitas,
        'focos_dengue': focos_dengue,
        'agentes_ativos': agentes_ativos,
        'marcadores_json': marcadores_json, # Enviando os pontos para a tela!
    }

    return render(request, 'dashboard.html', contexto)