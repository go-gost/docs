FROM squidfunk/mkdocs-material:8.4.1 AS builder

ADD . /src

WORKDIR /src

RUN mkdocs build -d site

WORKDIR /src/en

RUN mkdocs build -d /src/site/en/

WORKDIR /src/blog

RUN mkdocs build -d /src/site/blog/

FROM nginx:1.23-alpine

COPY --from=builder /src/site/ /usr/share/nginx/html/