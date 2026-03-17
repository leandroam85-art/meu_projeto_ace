from django.contrib.gis.db import models
from django.contrib.auth.models import User

class Agente(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, null=True, blank=True)
    nome = models.CharField(max_length=255)
    def __str__(self): return self.nome

class Imovel(models.Model):
    TIPO_CHOICES = [('R', 'Residencial'), ('C', 'Comercial'), ('TB', 'Terreno Baldio'), ('PE', 'Ponto Estratégico'), ('O', 'Outro')]
    endereco = models.CharField(max_length=255)
    numero = models.CharField(max_length=50, blank=True, null=True)
    bairro = models.CharField(max_length=100)
    quarteirao = models.CharField(max_length=50, blank=True, null=True)
    tipo = models.CharField(max_length=2, choices=TIPO_CHOICES, default='R')
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    localizacao = models.PointField(null=True, blank=True, srid=4326)
    def __str__(self): return f"{self.endereco}, {self.numero} - {self.bairro}"

class Visita(models.Model):
    STATUS_CHOICES = [('N', 'Normal'), ('F', 'Fechada'), ('R', 'Recusada')]
    imovel = models.ForeignKey(Imovel, on_delete=models.CASCADE)
    agente = models.ForeignKey(Agente, on_delete=models.SET_NULL, null=True)
    data_visita = models.DateTimeField(null=True, blank=True)
    ciclo = models.IntegerField(default=1)
    semana_epidemiologica = models.IntegerField(default=1)
    status = models.CharField(max_length=1, choices=STATUS_CHOICES, default='N')
    amostras_coletadas = models.IntegerField(default=0)
    quantidade_larvas = models.IntegerField(default=0)
    depositos_eliminados = models.IntegerField(default=0)
    dep_A1 = models.IntegerField(default=0)
    dep_A2 = models.IntegerField(default=0)
    dep_B = models.IntegerField(default=0)
    dep_C = models.IntegerField(default=0)
    dep_D1 = models.IntegerField(default=0)
    dep_D2 = models.IntegerField(default=0)
    dep_E = models.IntegerField(default=0)
    larvicida_1_tipo = models.CharField(max_length=100, blank=True, null=True)
    larvicida_1_qtde = models.FloatField(default=0)
    larvicida_1_dep_tratados = models.IntegerField(default=0)
    larvicida_2_tipo = models.CharField(max_length=100, blank=True, null=True)
    larvicida_2_qtde = models.FloatField(default=0)
    larvicida_2_dep_tratados = models.IntegerField(default=0)
    adulticida_tipo = models.CharField(max_length=100, blank=True, null=True)
    adulticida_qtde = models.FloatField(default=0)
    observacoes = models.TextField(blank=True, null=True)
    def __str__(self): return f"Visita {self.id} - {self.imovel}"

# NOVA TABELA: VACINAÇÃO ANTIRRÁBICA
class VacinacaoAntirrabica(models.Model):
    agente = models.ForeignKey(Agente, on_delete=models.SET_NULL, null=True)
    localidade = models.CharField(max_length=255, blank=True, null=True)
    caes_vacinados = models.IntegerField(default=0)
    gatos_vacinados = models.IntegerField(default=0)
    data_vacinacao = models.DateTimeField(null=True, blank=True)
    localizacao = models.PointField(null=True, blank=True, srid=4326)

    def __str__(self):
        return f"Vacinação - {self.localidade} ({self.caes_vacinados} Cães, {self.gatos_vacinados} Gatos)"