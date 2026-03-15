# Usa uma versão leve do Linux com Python 3.10
FROM python:3.10-slim

# Evita que o Python crie arquivos .pyc desnecessários e força o log no terminal
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Instala as bibliotecas de Sistema Operacional (Adicionado libgdal-dev como garantia)
RUN apt-get update && apt-get install -y \
    binutils libproj-dev gdal-bin libgdal-dev \
    libpango-1.0-0 libpangoft2-1.0-0 libjpeg-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Cria a pasta do sistema
WORKDIR /app

# Copia e instala as bibliotecas do Python
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copia o resto do código do projeto para dentro do servidor
COPY ./src /app/

# Define qual será o nome de usuário do Administrador
ENV DJANGO_SUPERUSER_USERNAME=admin
ENV DJANGO_SUPERUSER_EMAIL=admin@vilarica.mt.gov.br

# A ARMADILHA: Executa os comandos e, se falhar, segura a tela por 60s para lermos o erro!
CMD sh -c "python manage.py migrate; python manage.py createsuperuser --noinput; gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-10000}; echo '--- SERVIDOR CAIU! SEGURANDO A TELA PARA LER O ERRO ---'; sleep 60"