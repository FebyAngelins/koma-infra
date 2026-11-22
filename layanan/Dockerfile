# Image layanan Modul 08: dibangun pipeline GitHub Actions (.github/workflows/m08.yml),
# tidak perlu Docker di laptop. Versi ditanam saat build: docker build --build-arg VERSI=8.0.0
FROM public.ecr.aws/docker/library/python:3.12-slim
ARG VERSI=0.0.0
ENV KOMA_VERSI=${VERSI} PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
RUN pip install --no-cache-dir "boto3>=1.34,<2" && useradd --system --uid 10001 koma
WORKDIR /app
COPY koma_layanan.py .
USER 10001
EXPOSE 8080
CMD ["python3", "koma_layanan.py", "--port", "8080"]
