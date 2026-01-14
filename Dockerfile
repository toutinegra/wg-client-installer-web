# ---------------------------
# Imagem base
# ---------------------------
FROM python:3.14-slim

# ---------------------------
# Variáveis de ambiente
# ---------------------------
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# ---------------------------
# Diretório de trabalho
# ---------------------------
WORKDIR /wg-client-installer

# ---------------------------
# Copia os arquivos
# ---------------------------
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

# ---------------------------
# Expor a porta
# ---------------------------
EXPOSE 5000

# ---------------------------
# Comando padrão para rodar o Flask
# ---------------------------
CMD ["flask", "run"]