"""
Django settings for config project.
"""

from pathlib import Path
import os
from urllib.parse import urlparse

# Caminho base do projeto
BASE_DIR = Path(__file__).resolve().parent.parent

# Chave de segurança
SECRET_KEY = 'django-insecure-&p=l9_%+2$x&x%ebp@_^!saqcb&mlzlb6@p5s6ze*v6!ji2^^l'

# DEBUG ativo
DEBUG = True

ALLOWED_HOSTS = ['*']

# Permissões para o Render
CSRF_TRUSTED_ORIGINS = [
    'https://*.onrender.com',
]

# Definição dos Aplicativos
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles', 
    
    # NOSSOS APLICATIVOS E BIBLIOTECAS:
    'django.contrib.gis', 
    'rest_framework',     
    'rest_framework.authtoken',
    'endemias',           
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware', 
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# --- BANCO DE DADOS ---
DATABASE_URL = os.environ.get('DATABASE_URL')

if DATABASE_URL:
    url = urlparse(DATABASE_URL)
    DATABASES = {
        'default': {
            'ENGINE': 'django.contrib.gis.db.backends.postgis',
            'NAME': url.path[1:],
            'USER': url.username,
            'PASSWORD': url.password,
            'HOST': url.hostname,
            'PORT': url.port,
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.contrib.gis.db.backends.postgis',
            'NAME': 'sistema_endemias',
            'USER': 'admin_saude',
            'PASSWORD': 'senha_super_segura',
            'HOST': 'db', 
            'PORT': '5432',
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# --- A BLINDAGEM DO IDIOMA E REDIRECIONAMENTO ---
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'America/Cuiaba'
USE_I18N = False
USE_TZ = True

# ESTA LINHA RESOLVE O ERRO: Diz exatamente para onde ir quando pedir login, sem tentar "traduzir" a rota.
LOGIN_URL = '/admin/login/'

# Arquivos Estáticos
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'