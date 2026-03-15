"""
Django settings for config project.
"""

from pathlib import Path
import os
from urllib.parse import urlparse  # <-- ADICIONADO: Tradutor de links de Banco de Dados

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-&p=l9_%+2$x&x%ebp@_^!saqcb&mlzlb6@p5s6ze*v6!ji2^^l'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

# LIBERADO PARA QUALQUER NGROK OU RENDER ACESSAR
ALLOWED_HOSTS = ['*']

# NOVA REGRA: PERMITE QUE O APLICATIVO ENVIE DADOS (POST/PUT) PELO NGROK E RENDER
CSRF_TRUSTED_ORIGINS = [
    'https://*.ngrok-free.app',
    'https://*.ngrok-free.dev',
    'https://*.onrender.com',  # <-- ADICIONADO: Permissão para o Render não bloquear envios
]

# Application definition
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
    'rest_framework.authtoken',  # <--- O Porteiro!
    'endemias',           
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
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

# Database - LÓGICA INTELIGENTE PARA SUPABASE E LOCAL
DATABASE_URL = os.environ.get('DATABASE_URL')

if DATABASE_URL:
    # Se o Render mandar o link do Supabase, o Django lê, divide as partes e usa o motor PostGIS:
    url = urlparse(DATABASE_URL)
    DATABASES = {
        'default': {
            'ENGINE': 'django.contrib.gis.db.backends.postgis', # <-- MOTOR DE MAPAS NA NUVEM!
            'NAME': url.path[1:],
            'USER': url.username,
            'PASSWORD': url.password,
            'HOST': url.hostname,
            'PORT': url.port,
        }
    }
else:
    # Configuração antiga (para o seu Docker local não quebrar quando testar no PC)
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

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Cuiaba'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static')

# Media files (Fotos dos focos, etc)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'