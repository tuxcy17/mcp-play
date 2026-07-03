---
type: how-to
tickets: []
---

# CI/CD — Guide opérationnel

Trois workflows GitHub Actions couvrent l'intégration, la livraison continue et le nettoyage du registry.
Voir [ADR-0001](../docs/decisions/adr-0001-ci-cd-github-actions.md) pour la justification des choix.

---

## Workflows

### `ci.yml` — Tests

Déclenché sur chaque commit d'une PR **et** sur chaque push vers `main` (merge inclus).

```
checkout → setup-uv → uv sync --frozen → ruff check → pytest
```

`uv sync --frozen` installe depuis `uv.lock` (groupes dev inclus par défaut).
Ajouter `mypy`, `coverage`, etc. dans `pyproject.toml` sous `[dependency-groups.dev]`.

### `docker.yml` — Image Docker

Déclenché sur chaque commit d'une PR et sur chaque push vers `main` ou un tag `v*.*.*`.

Stratégie de tags sur `ghcr.io/<owner>/<repo>` :

| Événement       | Tags produits                      |
|-----------------|------------------------------------|
| Push `main`     | `main`, `sha-<sha>`, `latest`      |
| PR interne      | `pr-<numéro>`, `sha-<sha>`         |
| Tag `v1.2.3`    | `1.2.3`, `sha-<sha>`               |
| PR de fork      | build seulement, **pas de push**   |

> **Limitation fork** : une PR venant d'un fork reçoit un `GITHUB_TOKEN` en lecture seule —
> GitHub refuse la publication sur ghcr.io par design (sécurité supply chain).

### `cleanup.yml` — Nettoyage GHCR

Supprime les versions d'images **non issues de `main`** (images de PR, branches feature,
layers non taggés). Voir `.ops/scripts/ghcr-cleanup.sh` pour la logique.

**Logique de conservation** :

| Tag présent sur la version | Conservée ? |
|----------------------------|-------------|
| `main`                     | oui         |
| `latest`                   | oui         |
| `v1.2.3` (semver)          | oui         |
| `pr-*`, `sha-*`, aucun     | **supprimée** |

**Déclencheurs** :

| Déclencheur           | Comportement                                        |
|-----------------------|-----------------------------------------------------|
| PR fermée (interne)   | nettoyage automatique des images de cette PR        |
| Planifié (dim. 03h)   | sweep hebdomadaire de rattrapage                    |
| `workflow_dispatch`   | manuel — `dry_run=true` par défaut pour prévisualiser |

---

## Script de nettoyage

`.ops/scripts/ghcr-cleanup.sh` est autonome et peut être lancé localement.

```bash
# Prévisualiser sans supprimer
DRY_RUN=true GH_TOKEN=$(gh auth token) \
  GITHUB_REPOSITORY=owner/repo \
  bash .ops/scripts/ghcr-cleanup.sh

# Supprimer pour de vrai
GH_TOKEN=$(gh auth token) \
  GITHUB_REPOSITORY=owner/repo \
  bash .ops/scripts/ghcr-cleanup.sh
```

Prérequis : `gh` CLI authentifiée avec le scope `packages:delete`.

---

## Permissions GHCR

Aucun secret à configurer. L'authentification utilise le `GITHUB_TOKEN` automatique avec
la permission `packages: write` déclarée dans chaque workflow.

Pour rendre une image **publique** après la première publication :
> GitHub → Settings du package → Change visibility → Public.

---

## Dockerfile

Build multi-stage avec uv :

1. **builder** — copie le binaire uv depuis `ghcr.io/astral-sh/uv:latest`, installe les dépendances dans `.venv` via `uv sync --frozen --no-dev`.
2. **final** — image python:3.12-slim sans uv ni outils de build ; seul `.venv` est copié.

`--mount=type=cache,target=/root/.cache/uv` accélère les rebuilds locaux en évitant les re-téléchargements.

**À adapter** :
- `CMD ["python", "-m", "app"]` → remplacer `app` par le module principal.
- Si le projet expose un script CLI déclaré dans `pyproject.toml`, utiliser directement son nom : `CMD ["mon-cli"]`.

### Build local

```bash
docker build -t dev-cli:local .
docker run --rm dev-cli:local
```

---

## Tests locaux

```bash
uv sync --frozen       # installe toutes les dépendances (dev inclus)
uv run ruff check .
uv run pytest --tb=short
```

---

## Monitoring des pipelines (sur demande)

Demander à Claude de vérifier les pipelines déclenche automatiquement les commandes ci-dessous.

```bash
# Lister les runs récents sur la branche courante
gh run list --branch $(git branch --show-current) --limit 5

# Voir les logs des étapes en échec
gh run view <run-id> --log-failed

# Suivre un run en cours en temps réel
gh run watch
```
