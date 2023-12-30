# build frontend
FROM node@sha256:7ce8b205d15e30fd395e5fa4000bcdf595fcff3f434fe75822e54e82a5f5cf82 as build-frontend

WORKDIR /app

COPY ./package.json ./
COPY ./package-lock.json ./
RUN npm install

COPY ./ ./
RUN npm run build

# Deploy everything
FROM nginx:latest

WORKDIR /usr/share/nginx/html/
RUN rm -rf ./*

# move frontend in public directory
COPY --from=build-frontend /app/build ./