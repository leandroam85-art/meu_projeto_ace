import json
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from .models import Visita, Agente, Imovel
from django.contrib.auth.models import User
from django.contrib import messages
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from django.db import models
from django.contrib.gis.geos import Point 

def converte_seguro(modelo, campo, valor):
    try:
        campo_db = modelo._meta.get_field(campo)
        if isinstance(campo_db, (models.IntegerField, models.FloatField, models.DecimalField)):
            if valor in ["", "S/N", None, "null"]: return 0
            return float(valor) if isinstance(campo_db, models.FloatField) else int(float(valor))
    except: pass
    return valor

@login_required(login_url='/admin/login/')
def dashboard_supervisor(request):
    if request.method == 'POST':
        acao = request.POST.get('acao') 
        if acao == 'cadastrar':
            nome = request.POST.get('nome')
            username = request.POST.get('username')
            senha = request.POST.get('senha')
            if User.objects.filter(username=username).exists(): messages.error(request, f'Erro: O usuário "{username}" já está em uso!')
            else:
                novo_user = User.objects.create_user(username=username, password=senha)
                Agente.objects.create(user=novo_user, nome=nome) 
                messages.success(request, f'Agente {nome} cadastrado com sucesso!')
        elif acao == 'redefinir_senha':
            agente_id = request.POST.get('agente_id')
            nova_senha = request.POST.get('nova_senha')
            try:
                agente = Agente.objects.get(id=agente_id)
                agente.user.set_password(nova_senha) 
                agente.user.save()
                messages.success(request, f'Senha redefinida com sucesso!')
            except Exception: messages.error(request, 'Erro ao redefinir a senha.')
        elif acao == 'excluir':
            agente_id = request.POST.get('agente_id')
            try:
                agente = Agente.objects.get(id=agente_id)
                if agente.user: agente.user.delete()
                else: agente.delete()
                messages.warning(request, f'Agente removido!')
            except Exception: messages.error(request, 'Erro ao excluir o agente.')

    total_visitas = Visita.objects.count()
    agentes_ativos = Agente.objects.count()
    agentes_lista = Agente.objects.all().order_by('nome') 
    focos_dengue = Visita.objects.filter(amostras_coletadas__gt=0).count()
    visitas_com_foco = Visita.objects.filter(amostras_coletadas__gt=0)
    
    visitas_rotina = Visita.objects.exclude(imovel__tipo='PE').select_related('imovel', 'agente').order_by('-data_visita')[:500]
    visitas_pe = Visita.objects.filter(imovel__tipo='PE').select_related('imovel', 'agente').order_by('-data_visita')[:500]
    
    # ---> NOVO: Pegando todas as visitas ordenadas para agrupar no painel
    todas_visitas = Visita.objects.select_related('imovel', 'agente').order_by('imovel__bairro', 'imovel__quarteirao', '-data_visita')
    
    marcadores = []
    for visita in visitas_com_foco:
        try:
            lat = getattr(visita.imovel, 'latitude', None)
            lng = getattr(visita.imovel, 'longitude', None)
            if hasattr(visita.imovel, 'localizacao') and visita.imovel.localizacao:
                lng = getattr(visita.imovel.localizacao, 'x', lng)
                lat = getattr(visita.imovel.localizacao, 'y', lat)
            if lat is not None and lng is not None:
                marcadores.append({'lat': float(lat), 'lng': float(lng), 'descricao': f"Tubitos: {visita.amostras_coletadas} <br>Data: {visita.data_visita.strftime('%d/%m/%Y')}"})
        except Exception: continue

    marcadores_json = json.dumps(marcadores)
    contexto = {
        'total_visitas': total_visitas, 'focos_dengue': focos_dengue, 'agentes_ativos': agentes_ativos,
        'agentes_lista': agentes_lista, 'marcadores_json': marcadores_json,
        'visitas_rotina': visitas_rotina, 'visitas_pe': visitas_pe,
        'todas_visitas': todas_visitas, # ---> ENVIANDO PARA O HTML
    }
    return render(request, 'dashboard.html', contexto)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_personalizado(request):
    usuario = request.data.get('username') or request.data.get('usuario') or request.data.get('user')
    senha = request.data.get('password') or request.data.get('senha')
    if not usuario or not senha: return Response({"erro": "Faltando usuário ou senha."}, status=400)
    user = authenticate(username=usuario, password=senha)
    if user is not None:
        token, created = Token.objects.get_or_create(user=user)
        return Response({"token": token.key})
    return Response({"erro": "Credenciais inválidas."}, status=400)

@api_view(['GET', 'POST', 'PUT'])
@permission_classes([AllowAny])
def api_imoveis(request, pk=None):
    if request.method == 'GET':
        imoveis = Imovel.objects.all()
        dados = []
        for i in imoveis:
            lat, lng = 0.0, 0.0
            if hasattr(i, 'localizacao') and i.localizacao:
                lng = getattr(i.localizacao, 'x', 0); lat = getattr(i.localizacao, 'y', 0)
            loc = f"POINT({lng} {lat})"
            b = getattr(i, 'bairro', '')
            dados.append({ "id": i.id, "endereco": str(getattr(i, 'endereco', 'S/N')).strip(), "numero": str(getattr(i, 'numero', 'S/N')).strip(), "bairro": str(b).strip() if b else '', "quarteirao": str(getattr(i, 'quarteirao', '')).strip(), "tipo": str(getattr(i, 'tipo', 'R')).strip(), "localizacao": loc })
        return Response(dados)
    elif request.method == 'POST':
        try:
            loc_str = request.data.get('localizacao', '')
            ponto = Point(0, 0)
            if loc_str.startswith('POINT'):
                try:
                    coords = loc_str.replace('POINT(', '').replace(')', '').split()
                    ponto = Point(float(coords[0]), float(coords[1]))
                except: pass
            novo = Imovel.objects.create(endereco=str(request.data.get('endereco', '')).strip(), numero=str(request.data.get('numero', 'S/N')).strip() or 'S/N', bairro=str(request.data.get('bairro', '')).strip(), quarteirao=converte_seguro(Imovel, 'quarteirao', str(request.data.get('quarteirao', 0)).strip()), tipo=str(request.data.get('tipo', 'R')).strip(), localizacao=ponto )
            return Response({"id": novo.id}, status=201)
        except Exception as e: return Response({"erro": str(e)}, status=400)
    elif request.method == 'PUT' and pk:
        try:
            imovel = Imovel.objects.get(id=pk)
            for campo, valor in request.data.items():
                if campo in ['id', 'localizacao']: continue
                if isinstance(valor, str): valor = valor.strip()
                try: setattr(imovel, campo, converte_seguro(Imovel, campo, valor))
                except: pass
            loc_str = request.data.get('localizacao', '')
            if loc_str.startswith('POINT'):
                try:
                    coords = loc_str.replace('POINT(', '').replace(')', '').split()
                    imovel.localizacao = Point(float(coords[0]), float(coords[1]))
                except: pass
            imovel.save()
            return Response({"id": imovel.id}, status=200)
        except Exception as e: return Response({"erro": str(e)}, status=400)

@api_view(['GET', 'POST', 'PUT'])
@permission_classes([AllowAny])
def api_visitas(request, pk=None):
    if request.method == 'GET':
        visitas = Visita.objects.all()
        dados = []
        for v in visitas:
            data_v = getattr(v, 'data_visita', None)
            data_str = data_v.isoformat() if hasattr(data_v, 'isoformat') else str(data_v) if data_v else None
            semana_epi = getattr(v, 'semana_epidemiologica', getattr(v, 'semana', 1))
            dados.append({ "id": v.id, "imovel": v.imovel.id if hasattr(v, 'imovel') and v.imovel else None, "status": getattr(v, 'status', 'N'), "semana_epidemiologica": semana_epi, "data_visita": data_str, "amostras_coletadas": getattr(v, 'amostras_coletadas', 0), "quantidade_larvas": getattr(v, 'quantidade_larvas', 0), "dep_A1": getattr(v, 'dep_A1', 0), "dep_A2": getattr(v, 'dep_A2', 0), "dep_B": getattr(v, 'dep_B', 0), "dep_C": getattr(v, 'dep_C', 0), "dep_D1": getattr(v, 'dep_D1', 0), "dep_D2": getattr(v, 'dep_D2', 0), "dep_E": getattr(v, 'dep_E', 0) })
        return Response(dados)
    elif request.method == 'POST':
        try:
            imovel_id = request.data.get('imovel')
            imovel = Imovel.objects.filter(id=imovel_id).first()
            if not imovel: return Response({"erro": "Imóvel não encontrado"}, status=400)
            nova = Visita(imovel=imovel)
            
            agente_username = request.data.get('agente_username')
            agente = None
            if agente_username:
                agente = Agente.objects.filter(user__username=agente_username).first()
            if not agente:
                agente = Agente.objects.filter(id=request.data.get('agente')).first()
            if not agente:
                agente = Agente.objects.first()
            nova.agente = agente

            for campo, valor in request.data.items():
                alvo = campo
                if campo == 'semana_epidemiologica' and not hasattr(nova, 'semana_epidemiologica') and hasattr(nova, 'semana'): alvo = 'semana'
                if alvo not in ['id', 'imovel', 'agente', 'data_visita', 'localizacao']:
                    if isinstance(valor, str): valor = valor.strip()
                    try: setattr(nova, alvo, converte_seguro(Visita, alvo, valor))
                    except: pass
            if hasattr(nova, 'data_visita') and request.data.get('data_visita'):
                from django.utils.dateparse import parse_datetime
                dt = parse_datetime(request.data['data_visita'])
                if dt: nova.data_visita = dt
            nova.save()
            return Response({"id": nova.id}, status=201)
        except Exception as e: return Response({"erro": str(e)}, status=400)
    elif request.method == 'PUT' and pk:
        try:
            visita = Visita.objects.get(id=pk)
            for campo, valor in request.data.items():
                if campo not in ['id', 'imovel', 'agente', 'data_visita']:
                    if isinstance(valor, str): valor = valor.strip()
                    try: setattr(visita, campo, converte_seguro(Visita, campo, valor))
                    except: pass
            visita.save()
            return Response({"id": visita.id}, status=200)
        except Exception as e: return Response({"erro": str(e)}, status=400)