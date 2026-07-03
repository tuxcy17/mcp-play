---
type: decision
id: ADR-0001
status: accepted
tickets: []
---

# ADR-0001 — Adoption de la Convention de documentation

## Contexte

Ce projet est piloté par IA. Pour garantir une documentation cohérente, non-redondante et sans dérive, une convention formelle est nécessaire — un agent qui débarque sans skill doit savoir où lire quoi et comment agir.

## Décision

Ce projet adopte la *Convention de documentation* telle que définie dans `.claude/conventions/doc.md`.

La convention définit :
- trois familles (vivant, daté, working-state) ;
- une structure de fichiers canonique avec chemin prévisible ;
- un cycle de mise à jour déclenché par signal (hook → détection de dérive → reconsolidation proposée par l'IA, validée par l'humain).

La convention est vendorisée localement dans `.claude/conventions/doc.md` (mode hybride) car le projet doit rester autonome hors ligne. Ce fichier est marqué comme miroir daté — la version canonique fait foi.

## Conséquences

- `AGENT.md` sert de routeur unique ; il ne porte aucune connaissance, uniquement des pointeurs.
- Toute documentation entre dans les quatre `type` par distillation validée, jamais par import brut.
- Le graphe de code (graphify) alimente `reference.md` ; les ADR alimentent `explanation.md`.
- Un commit clôt le cycle de documentation (§5).
