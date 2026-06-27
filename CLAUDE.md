# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Preview

```bash
# Install dependencies (Python 3 + pip)
pip install mkdocs-material mkdocs-material[imaging] jieba

# Preview Chinese docs (serves at http://localhost:8000)
mkdocs serve

# Preview English docs
cd en && mkdocs serve

# Build Chinese docs (output to site/)
mkdocs build -d site

# Build English docs (output to en/site/)
cd en && mkdocs build -d site

# Build both (Chinese + English under site/en/) — matches Dockerfile
mkdocs build -d site && cd en && mkdocs build -d /path/to/site/en/
```

### Docker build

```bash
# Production multi-arch build (matches CI)
docker build -t gost-docs .
```

The Dockerfile uses a multi-stage build:
1. `squidfunk/mkdocs-material:9.5.32` builds both Chinese and English sites
2. `nginx:1.23-alpine` serves the static output

## Architecture

This is the documentation site for [GOST](https://github.com/go-gost/gost) (GO Simple Tunnel), published at [gost.run](https://gost.run).

### Two-language setup

The site is bilingual (Chinese primary, English secondary), implemented as two independent MkDocs projects:

| Language | Config | Content root | Output |
|----------|--------|-------------|--------|
| Chinese (zh) | `mkdocs.yml` (root) | `docs/` | `site/` |
| English (en) | `en/mkdocs.yml` | `en/docs/` | `site/en/` |

Both configs share the same image assets (`docs/images/`) and overrides (`overrides/`). The English nav structure largely mirrors the Chinese one but is not guaranteed to be in sync — check both `mkdocs.yml` nav sections before assuming parity.

### Content organization

- `docs/concepts/` — Architecture and design concepts (service, chain, hop, auth, bypass, limiter, etc.)
- `docs/tutorials/` — Step-by-step guides (protocols, reverse proxy, TUN/TAP, DNS, etc.)
- `docs/reference/` — API reference for listeners, handlers, dialers, and connectors. Each component type has its own subdirectory with per-protocol files.
- `docs/getting-started/` — Quick start, configuration overview, FAQ
- `docs/blog/` — Blog posts (MkDocs blog plugin with categories, authors, archives)
- `docs/images/` — Images and diagrams shared across both languages

### Theme customization

- Theme: Material for MkDocs (`squidfunk/mkdocs-material:9.5.32`)
- Custom overrides in `overrides/` (currently only `main.html` with a minor customization)
- `jieba` is installed in the Docker build for Chinese text segmentation in search

### CI/CD (`.github/workflows/buildx.yaml`)

Triggered on push to `master` or version tags (`v*`):
- Builds a multi-arch Docker image (linux/amd64, linux/arm/v7, linux/arm64)
- Pushes to Docker Hub
- Tags: `latest`, `:vX.Y.Z`, `:vX.Y`, `:vX`, `:short-sha`

## Common tasks

### Adding a new reference page

1. Create the markdown file in the appropriate `docs/reference/<type>/` directory
2. Add a nav entry in `mkdocs.yml` under the correct reference section
3. If applicable, mirror the change in `en/mkdocs.yml` and create the English version in `en/docs/reference/<type>/`

### Adding a blog post

Create a markdown file in `docs/blog/posts/`. The filename determines the URL. Optionally add author metadata in `docs/blog/.authors.yml`. The blog plugin auto-generates the index, archive, and category pages.

### Editing the nav

The full site navigation is defined manually in `mkdocs.yml` (Chinese) and `en/mkdocs.yml` (English). New pages are not discoverable — they must be added to the nav to appear on the site.

## Notes

- CSS/JS customization on the theme is minimal (only a `main.html` override). Most styling relies on Material theme defaults.
- The `extra.analytics` block in both configs uses Google Analytics `G-V295TSM2WT`.
- The `extra.alternate` block in both configs adds language switcher links between Chinese (`/`) and English (`/en/`).
