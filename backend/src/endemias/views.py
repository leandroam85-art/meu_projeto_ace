import json
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from .models import Visita, Agente

# --- IMPORTAÇÕES PARA O CADASTRO NA TELA ---
from django.contrib.auth.models import User
from django.contrib import messages

# --- IMPORTAÇÕES PARA A API DO APLICATIVO ---
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token

@login_required(login_url='/admin/login/')
def dashboard_supervisor(request):

    # ==========================================
    # MOTOR DE CADASTRO DO MODAL
    # ==========================================
    if request.method == 'POST':
        nome = request.POST.get('nome')
        username = request.POST.get('username')
        senha = request.POST.get('senha')
        
        # Verifica se o usuário já existe para não dar erro feio na tela
        if User.objects.filter(username=username).exists():
            messages.error(request, f'Erro: O usuário "{username}" já está em uso!')
        else:
            # Cria o login (O Gatilho do models.py vai gerar o Token sozinho aqui!)
            novo_user = User.objects.create_user(username=username, password=senha)
            
            # Vincula o login ao Agente, salvando o nome dele
            Agente.objects.create(user=novo_user, nome=nome) 
            
            messages.success(request, f'Agente {nome} cadastrado com sucesso! Já pode testar no celular.')

    # ==========================================
    # DADOS DO DASHBOARD E MAPA
    # ==========================================
    total_visitas = Visita.objects.count()
    agentes_ativos = Agente.objects.count()

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
            # Se o imóvel não tiver coordenada cadastrada, ignora e não quebra o site
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


# ==========================================
# NOSSA FECHADURA INTELIGENTE PARA O APK
# ==========================================
@api_view(['POST'])
@permission_classes([AllowAny])
def login_personalizado(request):
    # O ESPIÃO: Isso vai imprimir no painel do Render exatamente o que o app mandar
    print("🕵️ DADOS RECEBIDOS DO APLICATIVO:", request.data)
    
    # Tenta ler o usuário e a senha, não importa se o app mandar em português ou inglês
    usuario = request.data.get('username') or request.data.get('usuario') or request.data.get('user')
    senha = request.data.get('password') or request.data.get('senha')
    
    # Se o app mandar vazio, ele avisa
    if not usuario or not senha:
        return Response({"erro": "Faltando usuário ou senha. Verifique os dados enviados pelo App!"}, status=400)
        
    # Verifica se a senha e o usuário batem com os cadastrados no Admin
    user = authenticate(username=usuario, password=senha)
    
    if user is not None:
        # Se achou e a senha está certa, gera e devolve o Token pro celular!
        token, created = Token.objects.get_or_create(user=user)
        return Response({"token": token.key})
    else:
        # Se a senha estiver errada
        return Response({"erro": "Credenciais inválidas. Tente novamente."}, status=400)