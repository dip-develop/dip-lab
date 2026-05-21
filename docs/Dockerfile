FROM ghcr.io/paperless-ngx/paperless-ngx:latest

RUN apt-get update && apt-get install -y \
    tesseract-ocr-eng \
    tesseract-ocr-deu \
    tesseract-ocr-ukr \
    tesseract-ocr-rus \
    && rm -rf /var/lib/apt/lists/*
