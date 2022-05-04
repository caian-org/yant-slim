FROM node:18.1.0-alpine AS base
MAINTAINER Caian R. Ertl <hi@caian.org>

RUN npm i -g npm@latest
RUN addgroup -S turing && adduser -S turing -G turing
RUN mkdir -p /home/turing
RUN chown turing:turing /home/turing
USER turing
WORKDIR /home/turing

FROM base AS package
USER root
COPY package.json .
COPY package-lock.json .

FROM package AS dev-deps
RUN npm i

FROM package AS prod-deps
RUN apk add --no-cache curl
RUN curl -sf https://gobinaries.com/tj/node-prune | sh
RUN NODE_ENV="production" npm i --only=production
RUN node-prune
RUN chown -R turing:turing node_modules package.json package-lock.json

FROM dev-deps AS build
COPY src src
COPY .babelrc.js .
RUN npm run check:all

FROM package AS dependencies
RUN export NODE_ENV="production"
RUN npm install --only=production
RUN chown -R turing:turing node_modules

FROM package AS run
USER turing
COPY --from=prod-deps ["/home/turing/node_modules", "./node_modules"]
COPY --from=build ["/home/turing/src", "./src"]
ENTRYPOINT ["npm", "start"]
