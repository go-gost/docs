FROM squidfunk/mkdocs-material:9.4.14 AS builder

ADD . /src

WORKDIR /src

RUN mkdocs build -d site

WORKDIR /src/en

RUN mkdocs build -d /src/site/en/

FROM nginx:1.23-alpine

COPY --from=builder /src/site/ /usr/share/nginx/html/