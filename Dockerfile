FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ARG VITE_AUTH_URL
ARG VITE_ASSESSMENT_URL
ARG VITE_THERAPIST_URL
ENV VITE_AUTH_URL=$VITE_AUTH_URL
ENV VITE_ASSESSMENT_URL=$VITE_ASSESSMENT_URL
ENV VITE_THERAPIST_URL=$VITE_THERAPIST_URL
RUN npm run build

FROM nginx:alpine

RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

RUN addgroup -S wellnest && adduser -S wellnest -G wellnest

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

RUN chown -R wellnest:wellnest /usr/share/nginx/html && \
    chown -R wellnest:wellnest /var/cache/nginx && \
    chown -R wellnest:wellnest /var/log/nginx && \
    chown -R wellnest:wellnest /etc/nginx/conf.d && \
    mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp \
             /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R wellnest:wellnest /tmp/client_temp /tmp/proxy_temp \
             /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

USER wellnest

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
