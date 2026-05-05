FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --legacy-peer-deps
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY docker-entrypoint.d/ /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/*.sh \
    && test -x /docker-entrypoint.d/10-generate-config.sh \
    && /docker-entrypoint.d/10-generate-config.sh \
    && test -s /usr/share/nginx/html/var/conf/judgels-client.js
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
