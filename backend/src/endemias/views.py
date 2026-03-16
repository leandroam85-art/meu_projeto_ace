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

@login_required(login_url='/admin/login/')
def dashboard_supervisor(request):

    # ==========================================
    # MOTOR DE GERENCIAMENTO (CADASTRAR, EDITAR, EXCLUIR)
    # ==========================================
    if request.method == 'POST':
        acao = request.POST.get('acao') 

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
                agente.user.set_password(nova_senha) 
                agente.user.save()
                messages.success(request, f'Senha do agente "{agente.nome}" redefinida com sucesso!')
            except Exception as e:
                messages.error(request, 'Erro ao redefinir a senha.')

        # AÇÃO 3: EXCLUIR AGENTE
        elif acao == 'excluir':
            agente_id = request.POST.get('agente_id')
            try:
                agente = Agente.objects.get(id=agente_id)
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
    agentes_lista = Agente.objects.all().order_by('nome') 

    focos_dengue = Visita.objects.filter(amostras_coletadas__gt=0).count()
    visitas_com_foco = Visita.objects.filter(amostras_coletadas__gt=0)
    
    marcadores = []
    for visita in visitas_com_foco:
        try:
            lat = getattr(visita.imovel, 'latitude', None)
            lng = getattr(visita.imovel, 'longitude', None)
            if lat and lng:
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
        'agentes_lista': agentes_lista, 
        'marcadores_json': marcadores_json,
    }

    return render(request, 'dashboard.html', contexto)


# ==========================================
# NOSSA FECHADURA INTELIGENTE PARA O APK
# ==========================================
@api_view(['POST'])
@permission_classes([AllowAny])
def login_personalizado(request):
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
# API DE IMÓVEIS BLINDADA
# ==========================================
@api_view(['GET', 'POST', 'PUT'])
@permission_classes([AllowAny])
def api_imoveis(request, pk=None):
    if request.method == 'GET':
        imoveis = Imovel.objects.all()
        dados = []
        for i in imoveis:
            # Embala a latitude e longitude pro formato que o celular entende
            loc = ""
            lat = getattr(i, 'latitude', None)
            lng = getattr(i, 'longitude', None)
            if lat and lng:
                loc = f"POINT({lng} {lat})"

            dados.append({
                "id": i.id, 
                "endereco": getattr(i, 'endereco', 'S/N'), 
                "numero": getattr(i, 'numero', 'S/N'), 
                "bairro": getattr(i, 'bairro', ''), 
                "quarteirao": getattr(i, 'quarteirao', ''), 
                "tipo": getattr(i, 'tipo', 'R'),
                "localizacao": loc
            })
        return Response(dados)
        
    elif request.method == 'POST':
        # Recebe o POINT do celular e quebra em latitude e longitude limpas
        loc_str = request.data.get('localizacao', '')
        lat, lng = 0.0, 0.0
        if loc_str.startswith('POINT'):
            try:
                coords = loc_str.replace('POINT(', '').replace(')', '').split()
                lng = float(coords[0])
                lat = float(coords[1])
            except: pass
        
        novo = Imovel.objects.create(
            endereco=request.data.get('endereco', ''),
            numero=request.data.get('numero', 'S/N'),
            bairro=request.data.get('bairro', ''),
            quarteirao=request.data.get('quarteirao', ''),
            tipo=request.data.get('tipo', 'R'),
            latitude=lat,     
            longitude=lng     
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
# API DE VISITAS BLINDADA
# ==========================================
@api_view(['GET', 'POST', 'PUT'])
@permission_classes([AllowAny])
def api_visitas(request, pk=None):
    if request.method == 'GET':
        visitas = Visita.objects.all()
        dados = []
        for v in visitas:
            data_v = getattr(v, 'data_visita', None)
            dados.append({
                "id": v.id, 
                "imovel": v.imovel.id if hasattr(v, 'imovel') and v.imovel else None, 
                "status": getattr(v, 'status', 'N'), 
                "semana_epidemiologica": getattr(v, 'semana_epidemiologica', 1),
                "data_visita": data_v.isoformat() if data_v else None,
                "amostras_coletadas": getattr(v, 'amostras_coletadas', 0), 
                "quantidade_larvas": getattr(v, 'quantidade_larvas', 0),
                "dep_A1": getattr(v, 'dep_A1', 0), "dep_A2": getattr(v, 'dep_A2', 0), 
                "dep_B": getattr(v, 'dep_B', 0), "dep_C": getattr(v, 'dep_C', 0), 
                "dep_D1": getattr(v, 'dep_D1', 0), "dep_D2": getattr(v, 'dep_D2', 0), 
                "dep_E": getattr(v, 'dep_E', 0)
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
                depositos_eliminados=request.data.get('depositos_eliminados', 0)
            )
            
            # Salva os depósitos sem quebrar
            for campo in ['dep_A1', 'dep_A2', 'dep_B', 'dep_C', 'dep_D1', 'dep_D2', 'dep_E']:
                if hasattr(nova, campo):
                    setattr(nova, campo, request.data.get(campo, 0))
            nova.save()
            
            return Response({"id": nova.id}, status=201)
        except Exception as e:
            return Response({"erro": str(e)}, status=400)
            
    elif request.method == 'PUT' and pk:
        visita = Visita.objects.get(id=pk)
        visita.status = request.data.get('status', getattr(visita, 'status', 'N'))
        visita.amostras_coletadas = request.data.get('amostras_coletadas', getattr(visita, 'amostras_coletadas', 0))
        visita.quantidade_larvas = request.data.get('quantidade_larvas', getattr(visita, 'quantidade_larvas', 0))
        visita.depositos_eliminados = request.data.get('depositos_eliminados', getattr(visita, 'depositos_eliminados', 0))
        visita.save()
        return Response({"id": visita.id}, status=200)