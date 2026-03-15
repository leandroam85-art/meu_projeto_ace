# Usa uma versão leve do Linux com Python 3.10
FROM python:3.10-slim

# Evita que o Python crie arquivos .pyc desnecessários e força o log no terminal
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Instala as bibliotecas de Sistema Operacional (PostGIS e WeasyPrint exigem isso)
RUN apt-get update && apt-get install -y \
    binutils libproj-dev gdal-bin \
    libpango-1.0-0 libpangoft2-1.0-0 libjpeg-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Cria a pasta do sistema
WORKDIR /app

# Copia e instala as bibliotecas do Python
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copia o resto do código do projeto para dentro do servidor
COPY ./src /app/