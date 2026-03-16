import json
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from .models import Visita, Agente, Imovel

# --- IMPORTAÇÕES PARA O CADASTRO NA TELA ---
from django.contrib.auth.models import User
from django.contrib import messages

# --- IMPORTAÇÕES PARA A API DO APLICATIVO ---
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from django.contrib.gis.geos import Point

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

# ==========================================
# API DE IMÓVEIS (Para o App baixar e enviar)
# ==========================================
@api_view(['GET', 'POST', 'PUT'])
@permission_classes([AllowAny])
def api_imoveis(request, pk=None):
    if request.method == 'GET':
        imoveis = Imovel.objects.all()
        dados = [{"id": i.id, "endereco": i.endereco, "numero": i.numero, "bairro": i.bairro, "quarteirao": i.quarteirao, "tipo": i.tipo} for i in imoveis]
        return Response(dados)
        
    elif request.method == 'POST':
        loc_str = request.data.get('localizacao', '')
        ponto = Point(0, 0)
        if loc_str.startswith('POINT'):
            try:
                coords = loc_str.replace('POINT(', '').replace(')', '').split()
                ponto = Point(float(coords[0]), float(coords[1]))
            except: pass
        
        novo = Imovel.objects.create(
            endereco=request.data.get('endereco', ''),
            numero=request.data.get('numero', 'S/N'),
            bairro=request.data.get('bairro', ''),
            quarteirao=request.data.get('quarteirao', ''),
            tipo=request.data.get('tipo', 'R'),
            localizacao=ponto
        )
        return Response({"id": novo.id}, status=201)

    elif request.method == 'PUT' and pk:
        imovel = Imovel.objects.get(id=pk)
        imovel.endereco = request.data.get('endereco', imovel.endereco)
        imovel.numero = request.data.get('numero', imovel.numero)
        imovel.bairro = request.data.get('bairro', imovel.bairro)
        imovel.quarteirao = request.data.get('quarteirao', imovel.quarteirao)
        imovel.tipo = request.data.get('tipo', imovel.tipo)
        imovel.save()
        return Response({"id": imovel.id}, status=200)

# ==========================================
# API DE VISITAS (Para o App baixar e enviar)
# ==========================================
@api_view(['GET', 'POST', 'PUT'])
@permission_classes([AllowAny])
def api_visitas(request, pk=None):
    if request.method == 'GET':
        visitas = Visita.objects.all()
        dados = []
        for v in visitas:
            dados.append({
                "id": v.id, "imovel": v.imovel.id, "status": v.status, 
                "semana_epidemiologica": v.semana_epidemiologica,
                "data_visita": v.data_visita.isoformat() if v.data_visita else None,
                "amostras_coletadas": v.amostras_coletadas, "quantidade_larvas": v.quantidade_larvas,
                "dep_A1": v.dep_A1, "dep_A2": v.dep_A2, "dep_B": v.dep_B, "dep_C": v.dep_C, 
                "dep_D1": v.dep_D1, "dep_D2": v.dep_D2, "dep_E": v.dep_E
            })
        return Response(dados)
        
    elif request.method == 'POST':
        try:
            imovel = Imovel.objects.get(id=request.data.get('imovel'))
            agente_id = request.data.get('agente')
            agente = Agente.objects.filter(id=agente_id).first() if agente_id else Agente.objects.first()
            
            nova = Visita.objects.create(
                imovel=imovel, agente=agente,
                status=request.data.get('status', 'N'),
                ciclo=request.data.get('ciclo', 1),
                semana_epidemiologica=request.data.get('semana_epidemiologica', 1),
                amostras_coletadas=request.data.get('amostras_coletadas', 0),
                quantidade_larvas=request.data.get('quantidade_larvas', 0),
                depositos_eliminados=request.data.get('depositos_eliminados', 0),
                dep_A1=request.data.get('dep_A1', 0), dep_A2=request.data.get('dep_A2', 0),
                dep_B=request.data.get('dep_B', 0), dep_C=request.data.get('dep_C', 0),
                dep_D1=request.data.get('dep_D1', 0), dep_D2=request.data.get('dep_D2', 0),
                dep_E=request.data.get('dep_E', 0)
            )
            return Response({"id": nova.id}, status=201)
        except Exception as e:
            return Response({"erro": str(e)}, status=400)
            
    elif request.method == 'PUT' and pk:
        visita = Visita.objects.get(id=pk)
        visita.status = request.data.get('status', visita.status)
        visita.amostras_coletadas = request.data.get('amostras_coletadas', visita.amostras_coletadas)
        visita.quantidade_larvas = request.data.get('quantidade_larvas', visita.quantidade_larvas)
        visita.depositos_eliminados = request.data.get('depositos_eliminados', visita.depositos_eliminados)
        visita.save()
        return Response({"id": visita.id}, status=200)