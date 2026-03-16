from django.contrib.gis.db import models
from django.contrib.auth.models import User
from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver
from rest_framework.authtoken.models import Token

class Imovel(models.Model):
    TIPO_CHOICES = [
        ('R', 'Residencial'),
        ('C', 'Comercial'),
        ('TB', 'Terreno Baldio'),
        ('PE', 'Ponto Estratégico'),
        ('O', 'Outros'),
    ]

    endereco = models.CharField(max_length=255)
    numero = models.CharField(max_length=20, blank=True, null=True, default="S/N")
    bairro = models.CharField(max_length=100)
    quarteirao = models.CharField(max_length=50)
    tipo = models.CharField(max_length=2, choices=TIPO_CHOICES, default='R')
    localizacao = models.PointField()

    # --- CORREÇÃO PARA O MAPA NÃO QUEBRAR ---
    # Traduz as coordenadas do GeoDjango para o seu views.py conseguir ler 'latitude' e 'longitude'
    @property
    def latitude(self):
        return self.localizacao.y if self.localizacao else None

    @property
    def longitude(self):
        return self.localizacao.x if self.localizacao else None

    def __str__(self):
        return f"{self.endereco}, {self.numero} - {self.bairro}"


class Agente(models.Model):
    # --- CORREÇÃO PARA O CADASTRO FUNCIONAR ---
    # Liga o Agente ao sistema de login do Django
    user = models.OneToOneField(User, on_delete=models.CASCADE, null=True, blank=True)
    nome = models.CharField(max_length=100)
    # Deixei a matrícula aceitando vazio (null=True) para não travar o cadastro rápido no dashboard
    matricula = models.CharField(max_length=50, unique=True, null=True, blank=True) 

    def __str__(self):
        return self.nome


class Visita(models.Model):
    STATUS_CHOICES = [
        ('N', 'Normal (Inspecionado)'),
        ('F', 'Fechada'),
        ('R', 'Recusada'),
    ]

    imovel = models.ForeignKey(Imovel, on_delete=models.CASCADE, related_name='visitas')
    agente = models.ForeignKey(Agente, on_delete=models.CASCADE)
    
    # 📅 Dados Epidemiológicos e de Data/Hora
    data_visita = models.DateTimeField(auto_now_add=True)
    ciclo = models.IntegerField(default=1)
    semana_epidemiologica = models.IntegerField(default=1)
    
    status = models.CharField(max_length=1, choices=STATUS_CHOICES, default='N')

    # 🪣 Depósitos Inspecionados
    dep_A1 = models.IntegerField(default=0)
    dep_A2 = models.IntegerField(default=0)
    dep_B = models.IntegerField(default=0)
    dep_C = models.IntegerField(default=0)
    dep_D1 = models.IntegerField(default=0)
    dep_D2 = models.IntegerField(default=0)
    dep_E = models.IntegerField(default=0)

    # 🧪 Coleta e Ações
    amostras_coletadas = models.IntegerField(default=0)
    quantidade_larvas = models.IntegerField(default=0)
    depositos_eliminados = models.IntegerField(default=0)

    # ☠️ Tratamento Focal (Larvicida)
    larvicida_1_tipo = models.CharField(max_length=50, blank=True, null=True)
    larvicida_1_qtde = models.FloatField(default=0.0)
    larvicida_1_dep_tratados = models.IntegerField(default=0)

    larvicida_2_tipo = models.CharField(max_length=50, blank=True, null=True)
    larvicida_2_qtde = models.FloatField(default=0.0)
    larvicida_2_dep_tratados = models.IntegerField(default=0)

    # 💨 Tratamento Perifocal (Adulticida)
    adulticida_tipo = models.CharField(max_length=50, blank=True, null=True)
    adulticida_qtde = models.FloatField(default=0.0)

    # 📝 Outros
    observacoes = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Visita {self.id} - Imóvel {self.imovel.id} - Status: {self.status}"


# ==========================================
# GATILHO AUTOMÁTICO DE TOKENS PARA O APP
# ==========================================
@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def criar_token_automatico(sender, instance=None, created=False, **kwargs):
    # Toda vez que você salvar um usuário no modal, o Django passa por aqui e gera a chave sozinho!
    if created:
        Token.objects.create(user=instance)