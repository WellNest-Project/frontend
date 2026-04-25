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
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R wellnest:wellnest /usr/share/nginx/html && \
    chown -R wellnest:wellnest /var/cache/nginx && \
    chown -R wellnest:wellnest /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R wellnest:wellnest /var/run/nginx.pid

USER wellnest

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
