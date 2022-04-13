FROM squidfunk/mkdocs-material:8.1.4 AS builder

ADD . /src

WORKDIR /src

RUN mkdocs build -d site

WORKDIR /src/en

RUN mkdocs build -d /src/site/en/

FROM nginx:1.21-alpine

COPY --from=builder /src/site/ /usr/share/nginx/html/