FROM python:3.10-slim

# Impede o Python de gerar arquivos inúteis e garante logs em tempo real
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Instala bibliotecas de mapas e sistema
RUN apt-get update && apt-get install -y \
    binutils libproj-dev gdal-bin libgdal-dev \
    libpango-1.0-0 libpangoft2-1.0-0 libjpeg-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instala as dependências ( WhiteNoise incluído )
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt whitenoise gunicorn

COPY ./src /app/

# O COMANDO DA VITÓRIA:
# 1. Coleta o CSS (collectstatic)
# 2. Atualiza o Banco (migrate)
# 3. Tenta criar o superusuário (se já existir, ele pula sem erro)
# 4. Liga o servidor
CMD sh -c "python manage.py collectstatic --noinput; \
           python manage.py migrate; \
           python manage.py createsuperuser --noinput || true; \
           gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-10000}"