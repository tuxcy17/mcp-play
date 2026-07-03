# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Ce projet suit la *Convention de documentation* (`.claude/conventions/doc.md`).
Avant d'écrire le moindre document ou de proposer un commit, lis-la. En cas de conflit, la convention fait foi.



## graphify

Les directives graphify vivent dans `CLAUDE.md` (généré, ne pas éditer à la main).

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

---

## Commandes

```bash
make install      # uv sync --all-groups (premier setup)
make lint         # ruff check + format check
make format       # ruff format + fix
make test         # pytest
make test ARGS="-k test_name"  # test unitaire ciblé
make run          # python -m mcp_play
make build        # docker build -t mcp-play .
make docker-run   # docker run --env-file .env mcp-play
```

## Variables d'environnement

Tous les secrets passent exclusivement par des variables d'environnement. Toute nouvelle variable doit être documentée dans `.env.example` avant utilisation. Copier `.env.example` → `.env` en local (gitignore).
This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

## GitHub CLI

`gh` est disponible dans l'environnement de développement et doit être utilisé pour toutes les opérations GitHub : PRs, issues, checks CI, releases. Ne pas utiliser l'API REST directement si `gh` couvre le besoin.

## Architecture

```
src/mcp_play/    # package principal
tests/           # pytest, miroir plat de src/
```

Entry point : `src/mcp_play/__main__.py` → `main()`.
