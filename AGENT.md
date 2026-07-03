# AGENT.md — doc-init

Ce projet suit la *Convention de documentation* (`.claude/conventions/doc.md`).
Avant d'écrire le moindre document ou de proposer un commit, lis-la. En cas de conflit, la convention fait foi.

Adoption actée par [ADR-0001](docs/decisions/adr-0001-adoption-convention-documentation.md).

---

## Carte des familles

| Question | Fichier | Nature |
|---|---|---|
| Le QUOI | `docs/reference.md` | Vivant — dérivé du graphe de code |
| Le POURQUOI | `docs/explanation.md` | Vivant — projeté des ADR |
| Le COMMENT | `docs/how-to.md` | Vivant — pointe vers les scripts/CI |
| Les décisions | `docs/decisions/` | Daté — append-only, immuable |
| État en cours | `.context/SESSION.md` | Working-state — versionné |

## Table source ↔ type (§6)

| `type` | Source | Régénération |
|---|---|---|
| `reference` | graphe de code | Régénéré, jamais patché |
| `explanation` | ADR | Reconsolidé |
| `how-to` | scripts / CI | Repointé |
| `decision` | Écrit à la main | Jamais modifié (append-only) |

## Protocole de fraîcheur

1. Avant d'agir, lire `.context/freshness.md`.
2. Interroger le graphe vivant via MCP — ne jamais considérer `graphify-out/` comme une vérité figée.
3. Si un doc vivant est en retard sur son signal (code changé, ADR créé), proposer une reconsolidation — jamais régénérer à l'aveugle.

## Outillage

Les directives graphify vivent dans `CLAUDE.md` (généré, ne pas éditer à la main).
