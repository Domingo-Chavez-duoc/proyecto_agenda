# ── Stage 1: Build Flutter web ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS builder

WORKDIR /app

# Cache de dependencias
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar fuentes y compilar web
COPY . .
RUN flutter build web --release \
    --dart-define=API_URL=\${API_URL:-http://localhost:5000/api}

# ── Stage 2: Nginx para servir la web ─────────────────────────────────────────
FROM nginx:alpine AS runner

COPY --from=builder /app/build/web /usr/share/nginx/html

# Config de nginx para SPA (redirige todo a index.html)
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
