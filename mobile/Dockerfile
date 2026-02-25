# Build Flutter Web (production)
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release -t lib/main_web.dart \
    --dart-define=API_BASE_URL=https://nawafeth-backend.onrender.com

# Serve built files with nginx (SPA-friendly)
FROM nginx:alpine

# Render sets PORT at runtime. Official nginx image auto-renders templates in
# /etc/nginx/templates/*.template using env vars before startup.
COPY nginx.render.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 10000
