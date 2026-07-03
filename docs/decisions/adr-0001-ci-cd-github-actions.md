---
type: decision
id: ADR-0001
status: accepted
tickets: []
---

# ADR-0001 — CI/CD via GitHub Actions + GHCR

## Contexte

Le projet a besoin d'une intégration continue (tests à chaque commit, sur PR et au merge)
et d'une livraison continue (image Docker publiée à chaque commit).

## Décision

GitHub Actions pour la CI/CD, GitHub Container Registry (`ghcr.io`) pour les images Docker.

## Justification

**GitHub Actions** : natif à l'hébergement git, aucune infrastructure externe à maintenir.
Le `GITHUB_TOKEN` automatique évite tout secret supplémentaire pour l'authentification.

**GHCR** : co-localisé avec le code et les Actions. Permissions via `GITHUB_TOKEN` avec
`packages: write` — aucun PAT à rotation à gérer. Accès contrôlé par les droits du dépôt.

**Deux workflows distincts** (`ci.yml` / `docker.yml`) : séparation des responsabilités.
Les tests ne dépendent pas du build Docker et peuvent évoluer indépendamment.

**Build Docker sur chaque commit de PR** : feedback immédiat si le `Dockerfile` casse.
Le push est conditionné à l'origine de la PR (interne vs fork) pour éviter l'écriture
depuis un contexte non de confiance.

**Cache GitHub Actions** (`type=gha`) sur le build Docker : réduit le temps de build sur
des layers stables (base image, dépendances).

## Conséquences

- PRs depuis un fork : le build Docker s'exécute mais l'image n'est pas publiée.
  Limitation de sécurité GitHub (token read-only pour les forks). Acceptable : les
  contributeurs internes bénéficient du push, les forks de la validation.
- Un tag sémantique `v*.*.*` déclenche une image taggée avec la version — à utiliser
  pour les releases.
- Le `Dockerfile` et le step `pip install` dans `ci.yml` doivent être adaptés quand
  le projet a un `pyproject.toml` avec ses dépendances réelles.
