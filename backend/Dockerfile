FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Installation des dépendances système
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur non-root
RUN groupadd -g 1000 appgroup \
    && useradd -u 1000 -g appgroup -s /bin/bash -m appuser

# Copie et installation de la configuration du projet et des dépendances
COPY pyproject.toml .
RUN pip install --upgrade pip \
    && pip install -e ".[dev]"

# Copie du code source
COPY . .

# Ajustement des permissions pour l'utilisateur de dev
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]