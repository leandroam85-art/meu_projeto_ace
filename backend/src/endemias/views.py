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
    # MOTOR DE GERENCIAMENTO (CADASTRAR, EDITAR, EXCLUIR)
    # ==========================================
    if request.method == 'POST':
        acao = request.POST.get('acao') # Descobre qual botão o supervisor apertou

        # AÇÃO 1: CADASTRAR NOVO AGENTE
        if acao == 'cadastrar':
            nome = request.POST.get('nome')
            username = request.POST.get('username')
            senha = request.POST.get('senha')
            
            if User.objects.filter(username=username).exists():
                messages.error(request, f'Erro: O usuário "{username}" já está em uso!')
            else:
                novo_user = User.objects.create_user(username=username, password=senha)
                Agente.objects.create(user=novo_user, nome=nome) 
                messages.success(request, f'Agente {nome} cadastrado com sucesso!')

        # AÇÃO 2: REDEFINIR SENHA DO AGENTE
        elif acao == 'redefinir_senha':
            agente_id = request.POST.get('agente_id')
            nova_senha = request.POST.get('nova_senha')
            try:
                agente = Agente.objects.get(id=agente_id)
                agente.user.set_password(nova_senha) # Troca a senha com segurança
                agente.user.save()
                messages.success(request, f'Senha do agente "{agente.nome}" redefinida com sucesso!')
            except Exception as e:
                messages.error(request, 'Erro ao redefinir a senha.')

        # AÇÃO 3: EXCLUIR AGENTE
        elif acao == 'excluir':
            agente_id = request.POST.get('agente_id')
            try:
                agente = Agente.objects.get(id=agente_id)
                # Excluir o User já apaga o Agente e o Token dele automaticamente (Cascade)
                if agente.user:
                    agente.user.delete()
                else:
                    agente.delete()
                messages.warning(request, f'Agente removido do sistema!')
            except Exception as e:
                messages.error(request, 'Erro ao excluir o agente.')

    # ==========================================
    # DADOS DO DASHBOARD E MAPA
    # ==========================================
    total_visitas = Visita.objects.count()
    agentes_ativos = Agente.objects.count()
    agentes_lista = Agente.objects.all().order_by('nome') # Pega a lista para a tabela

    focos_dengue = Visita.objects.filter(amostras_coletadas__gt=0).count()
    visitas_com_foco = Visita.objects.filter(amostras_coletadas__gt=0)
    
    marcadores = []
    for visita in visitas_com_foco:
        try:
            lat = visita.imovel.latitude 
            lng = visita.imovel.longitude
            marcadores.append({
                'lat': float(lat),
                'lng': float(lng),
                'descricao': f"Amostras coletadas: {visita.amostras_coletadas} <br>Data: {visita.data_visita.strftime('%d/%m/%Y')}"
            })
        except Exception:
            continue

    marcadores_json = json.dumps(marcadores)

    contexto = {
        'total_visitas': total_visitas,
        'focos_dengue': focos_dengue,
        'agentes_ativos': agentes_ativos,
        'agentes_lista': agentes_lista, # Envia a lista para o HTML
        'marcadores_json': marcadores_json,
    }

    return render(request, 'dashboard.html', contexto)


# ==========================================
# NOSSA FECHADURA INTELIGENTE PARA O APK
# ==========================================
@api_view(['POST'])
@permission_classes([AllowAny])
def login_personalizado(request):
    print("🕵️ DADOS RECEBIDOS DO APLICATIVO:", request.data)
    usuario = request.data.get('username') or request.data.get('usuario') or request.data.get('user')
    senha = request.data.get('password') or request.data.get('senha')
    
    if not usuario or not senha:
        return Response({"erro": "Faltando usuário ou senha."}, status=400)
        
    user = authenticate(username=usuario, password=senha)
    if user is not None:
        token, created = Token.objects.get_or_create(user=user)
        return Response({"token": token.key})
    else:
        return Response({"erro": "Credenciais inválidas."}, status=400)