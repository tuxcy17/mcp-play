# Convention de documentation

Convention partagée pour la documentation produite autour d'un projet de code, conçue
pour être pilotable par une IA sans qu'elle invente, et non-redondante par construction.

## Principe fondateur

> **Une vérité = une source unique = un déclencheur unique.**

Chaque document a *une seule* source dont il dérive, et *un seul* événement qui le met à
jour. C'est cette discipline — et rien d'autre — qui garantit qu'aucune information n'est
écrite deux fois, que la documentation ne dérive pas du code, et qu'un agent peut s'y
fier pour agir.

`AGENT.md` ne *contient* aucune connaissance : il *route* vers les lieux où elle vit.

---

## 1. Les trois familles

Toute la convention découle d'un découpage en trois familles, selon leur régime de
versionnement et de vérité.

| Famille | Nature | Régime | Exemples |
|---|---|---|---|
| **Vivant** | état actuel de la vérité | versionné, réécrit/régénéré en place | `reference.md`, `explanation.md`, `how-to.md` |
| **Daté** | enregistrement d'un moment | versionné, **append-only**, immuable | ADR, post-mortems |
| **Working-state** | où on en est *maintenant* | brouillon de travail | `SESSION.md`, plans en cours, cache du graphe |

La règle de gitignore ne suit **pas** l'axe éphémère/persisté, mais l'axe
**reconstructible-ou-pas** :

- contenu original non reconstructible (un `SESSION.md`, un plan en cours) → **versionné** ;
- pure dérivation du code (sortie graphe) → **gitignoré** (cache).

---

## 2. Les deux mémoires longues

La famille *datée* repose sur deux substrats complémentaires, jamais redondants :

- **git / graphe de code** — mémoire *atomique et spatiale*, attachée au diff,
  interrogeable par fichier (`git blame` → `git log`). Porte le *quand / quoi / quelle
  séquence*. → alimente `reference.md`.
- **ADR** — mémoire *narrative et synthétique*, durable, racontée. Porte le *pourquoi*.
  → alimente `explanation.md`.

Chaque mémoire nourrit une **moitié distincte** du vivant, via un substrat différent.
C'est ce qui garantit zéro redondance entre les deux canaux.

```mermaid
flowchart LR
  commit[commit git] -->|hook déterministe| graph[graphe de code<br/>.context/cache/]
graph -->|IA, sur signal| ref[reference.md]
adr[ADR<br/>docs/decisions/] -->|IA, sur signal| exp[explanation.md]
scripts[scripts / CI] -->|pointe vers| howto[how-to.md]
```

---

## 3. Structure des fichiers

Layout cible, en **structure paresseuse** : un sous-dossier n'existe que lorsqu'un fichier
déborde. On part à plat, on ne découpe que sous la pression du volume.

```
<repo>/
├── AGENT.md              # contrat d'entrée : routeur humain pur (voir §4)
├── CLAUDE.md             # directives d'outil (graphify) — généré, ne pas éditer à la main
├── docs/
│   ├── reference.md      # le QUOI   — dérivé du code via le graphe
│   ├── explanation.md    # le POURQUOI — projeté des ADR
│   ├── how-to.md         # le COMMENT  — pointe vers l'exécutable (scripts/CI)
│   └── decisions/        # daté, append-only (ADR + post-mortems)
│       ├── adr-0001-*.md
│       └── adr-0007-*.md
└── .context/
    ├── SESSION.md        # working-state — VERSIONNÉ (continuité sessions longues)
    ├── freshness.md      # registre de fraîcheur — VERSIONNÉ (voir §7)
    └── cache/            # sortie graphe (graphify-out) — GITIGNORÉ
```

Notes de découpe paresseuse :

- `reference.md` devient `reference/` (avec `api/`, etc.) seulement quand l'archi + l'API
  ne tiennent plus ensemble. Si un seul fichier devient ingérable, c'est souvent un signal
  que le **repo** devrait être scindé, pas la doc.
- `decisions/` est intrinsèquement multi-fichiers (un fichier par décision) : c'est sa
  nature append-only.
- Le découpage par domaine/feature se récupère **dans** un fichier (sections par bounded
  context), pas dans l'arborescence : pour un projet piloté par IA, la prévisibilité du
  chemin canonique bat la proximité.

### Cartographie Diátaxis

| Mode Diátaxis | Fichier | Source de vérité | Trigger de MAJ |
|---|---|---|---|
| Reference | `reference.md` | graphe de code (couche AST) | le code a changé |
| Explanation | `explanation.md` | ADR consolidés | un ADR créé/superseded |
| How-to | `how-to.md` | scripts / Makefile / CI | une procédure a changé |
| Tutorials | (replié dans le `README`) | humain, hors boucle agent | manuel, optionnel |

`reference.md` ne recopie pas le graphe : il en est la **synthèse lisible**.
`explanation.md` ne recopie pas chaque ADR : il intègre leur **résultat net courant** en
récit cohérent et les *cite*. Un ADR *superseded* disparaît de l'explanation ; seul
l'effet de son successeur subsiste. Un `how-to` ne recopie pas une commande : il **pointe**
vers la cible exécutable réelle et n'explique que le *contexte* d'usage.

---

## 4. `AGENT.md` — le routeur

`AGENT.md` est **écrit à la main**, 100 % humain, jamais pollué par du généré-outil. Il ne
contient que **trois choses, toutes des pointeurs** :

1. **La carte des familles** — le quoi → `reference.md`, le pourquoi → `explanation.md`,
   le comment → `how-to.md`, les décisions datées → `docs/decisions/`.
2. **Le protocole de fraîcheur** — avant d'agir, lire `.context/freshness.md` ; le graphe
   vivant est interrogeable via MCP ; ne jamais croire `.context/cache/` comme une vérité.
3. **Le pointeur vers cette convention** — `AGENT.md` ne *réénonce pas* les invariants
   d'écriture (un commit clôt le cycle de doc, une décision = un ADR immuable, l'IA propose
   et l'humain valide). Il **cite cette convention comme sa source**, exactement comme un
   commit cite un ADR. Réénoncer les règles serait recopier une vérité au lieu de pointer
   vers sa source unique — l'erreur même que la convention combat.

C'est aussi dans `AGENT.md` qu'est déclarée, **une seule fois**, la table source ↔ `type`
(voir §6), pour ne pas la répéter dans chaque fichier.

Les directives de l'outillage (graphify) vivent dans un `CLAUDE.md` séparé, traité comme
généré/jetable. `AGENT.md` le mentionne en une ligne, sans l'absorber.

### `AGENT.md` comme amorce — projets pilotés par IA sans skill

La convention est une règle d'écosystème : tes skills la connaissent, mais un agent qui
débarque sur un repo **sans skill** ne la connaît pas. Si elle n'est pas référencée *dans*
le repo, elle n'existe pas pour lui.

D'où une asymétrie de rôle :

- **Avec skills** — la skill porte le comportement, `AGENT.md` est un confort.
- **Sans skill, projet 100 % IA** — `AGENT.md` est le **seul** point d'entrée. Il devient
  *obligatoire* : c'est lui qui charge la convention dans le contexte de l'agent.

Sa première section doit donc être un pointeur explicite, du genre :

> Ce projet suit la *Convention de documentation* (`<lien/chemin>`). Avant d'écrire le
> moindre document ou de proposer un commit, lis-la. En cas de conflit, la convention fait foi.

### Où vit la convention que `AGENT.md` cite

La convention est un document **vivant** ; la vendoriser dans chaque repo recréerait la
dérive (N copies divergentes) qu'on traque par ailleurs. Trois options :

| Option | Avantage | Coût |
|---|---|---|
| **Lien externe** (dépôt central) | source unique, MAJ partout d'un coup | nécessite l'accès ; perdue hors ligne |
| **Copie vendorisée** (`docs/_meta/`) | auto-suffisant, hors ligne | N copies à synchroniser |
| **Hybride** | lien canonique + miroir figé daté en repli | légère redondance assumée |

Reco : **lien externe par défaut**, bascule en **hybride** dès qu'un repo doit être autonome
(livré à un client, audité hors ligne, agent sans réseau). Le repli vendorisé est alors
marqué « miroir daté — voir l'original pour la version courante », pour que personne ne le
prenne pour la vérité.

### Le pattern ADR-0001 d'adoption

Le choix ci-dessus *est* une décision d'architecture du projet → donc un ADR. Le premier
ADR d'un repo piloté par IA est littéralement :

> **ADR-0001 — Ce projet adopte la *Convention de documentation*** (référencée par lien /
> vendorisée en mode hybride).

`AGENT.md` pointe alors vers cet ADR plutôt que de porter la règle en dur. Tout se referme :
`AGENT.md` route, l'ADR acte l'adoption, la convention fait foi. Même le *fait d'avoir
adopté la convention* est tracé dans la mémoire longue.

---

## 5. Le commit comme checkpoint unique

**Un commit clôt le cycle de documentation.** Au moment où l'agent propose le message de
commit (toujours proposé, jamais commité — l'humain relit et exécute), il vérifie en une
passe : *ce diff touche-t-il une décision (→ ADR), la structure (→ reference), une
procédure (→ how-to) ?*

La clé de jointure entre git et le corpus markdown est le **ticket**, en position fixe et
parsable dans le format de commit maison :

```
type: TICKET - subject

Description en prose. Cite l'ADR s'il existe (See ADR-0007).

Co-authored-by: AI
```

Le chemin de reconstruction de l'agent devient mécanique :

> `git blame <fichier>` → commits → IDs de tickets → résoudre vers les ADR / docs portant
> le même ticket → lire le *pourquoi*.

Le commit ne raconte jamais le *pourquoi* durable : il **pointe** dessus. Découpage des
niveaux de rationnel :

- **subject** = l'intention du diff (le *quoi*) ;
- **corps du commit** = le pourquoi *local*, jetable avec le commit ;
- **ADR** = le pourquoi *réutilisable et durable*, cité depuis potentiellement plusieurs commits.

### Ticket d'un commit de documentation

Une reconsolidation (régénérer `reference.md`, mettre à jour `explanation.md`) se fait
**dans la même unité de travail** que le changement qui l'a causée : le commit de doc
(`type: docs`) **hérite du ticket qui a provoqué la dérive**. Le refactor `GEO-310` qui fait
dériver `reference.md` ? La mise à jour part sous `GEO-310` aussi. Aucun nouveau type, aucun
format à changer.

Seul cas particulier : une dérive **détectée plus tard**, détachée de son travail d'origine.
Deux options, à fixer selon ton flux — rouvrir sous le ticket d'origine, ou un ticket de
housekeeping dédié pour les commits purement `docs`. C'est la seule situation que le format
de commit ne tranche pas seul.

> Distinguer « crée l'ADR » de « applique l'ADR » dans le message est **inutile** :
> `git log -- docs/decisions/adr-0007-*.md` donne le premier commit touchant le fichier,
> donc celui qui l'a créé. L'historique de fichier répond déjà à la question.

---

## 6. En-tête universel (frontmatter)

Tout document persisté porte un en-tête minimal. **L'identité stable** vit dans le
frontmatter ; **l'état mouvant** (la fraîcheur) vit dans `.context/freshness.md`. On ne
les mélange jamais.

```yaml
---
type: reference | explanation | how-to | decision
tickets: [GEO-142, GEO-208]
---
```

- `type` → route vers la famille. C'est tout ce dont l'agent a besoin pour savoir comment
  traiter le document.
- `tickets` → la clé de jointure vers git et les ADR. Optionnel pour une `reference` pure
  dérivée du graphe (elle n'appartient à aucun ticket).

Le champ `source` n'existe **pas** dans le frontmatter : il se **dérive du `type`** via une
table déclarée une seule fois dans `AGENT.md` :

| `type` | source | régénération |
|---|---|---|
| `reference` | graphe de code | régénéré, jamais patché |
| `explanation` | ADR | reconsolidé |
| `how-to` | scripts / CI | repointé |
| `decision` | écrit à la main | jamais modifié (append-only) |

### Extension ADR

Seuls les ADR étendent le socle, car leur immuabilité impose un cycle de vie :

```yaml
---
type: decision
id: ADR-0007
status: accepted | superseded
superseded-by: ADR-0012   # uniquement si superseded
tickets: [GEO-310]
---
```

> **Largeur du numéro d'ADR : 4 chiffres, partout.** Le pont git → ADR repose sur
> l'extraction du motif `ADR-NNNN` ; la largeur doit être identique dans le corps de commit,
> le `id:` du frontmatter et le nom de fichier (`adr-0007-*.md`), sinon la regex décroche.
> La convention de commit maison doit s'aligner sur cette largeur.

Les **post-mortems** sont traités comme un `type: decision` de sous-genre « analyse » tant
qu'ils restent rares : ils ne se supersedent pas, et s'ils débouchent sur un changement,
ils *engendrent* un ADR plutôt que d'en être un. Bascule vers un cinquième type
`postmortem` + renommage `decisions/` → `records/` seulement si le volume le justifie.

---

## 7. Détection de dérive et fraîcheur

Le déclencheur de mise à jour des docs vivants n'est **pas** « à chaque commit » mais
« quand une dérive est signalée ». Trois étages, l'IA n'intervient qu'au troisième :

| Étage | Quoi | Qui | Quand |
|---|---|---|---|
| 1 | régénère le graphe (`.context/cache/`) | hook, déterministe | chaque commit |
| 2 | détecte la dérive (SHA + structure AST) | hook, déterministe | chaque commit |
| 3 | reconsolide le doc vivant | **IA, proposé** | seulement si étage 2 a signalé |

Régénérer le graphe ≠ régénérer `reference.md`. Le premier est une transformation
déterministe (hook, hors IA, comme un build) ; le second demande du jugement (acte d'IA,
proposé puis validé).

Ce mécanisme est **générique** à toutes les familles vivantes : un commit qui crée un ADR
sans toucher `explanation.md` lève « explanation en retard sur les décisions », au même
titre qu'une dérive structurelle de `reference.md`.

### Registre de fraîcheur

Un fichier unique, `.context/freshness.md`, ancré sur les **SHA de commit** (jamais sur des
timestamps, qui mentent au rebase). Pour chaque doc vivant, il garde le commit sur lequel
il a été consolidé pour la dernière fois. Le hook compare, lève le flag ; l'IA reconsolide
et met à jour le marqueur.

> L'IA ne régénère jamais à l'aveugle ni à chaque commit : seulement sur signal. Un fix de
> null pointer ne déclenche aucune reconsolidation ; un `extract PaymentGateway` oui.

L'IA **propose** toujours, n'impose jamais : « ce changement impacte `explanation.md` à
cause de ADR-0012, je régénère ? » — l'humain valide.

---

## 8. Outillage

### Graphify — le moteur

[graphify](https://graphify.net/) est le constructeur de graphe de connaissance
multi-modal : il ingère le code *et* la documentation (et diagrammes), combine l'analyse
statique Tree-sitter (déterministe, pour les AST et graphes d'appel) avec une extraction
sémantique par LLM. Rôles dans cette convention :

- la **couche structurelle** (AST, call graph) est l'ancre déterministe de la détection de
  dérive de `reference.md` ;
- la **couche sémantique** est une pré-digestion enrichie, jamais un point de confiance ;
- le graphe étant multi-modal (code + docs), il fournit un moteur naturel à la détection
  de dérive générique (un nœud ADR sans arête vers `explanation.md` = dérive) ;
- son mode service (MCP) permet à l'agent d'**interroger le graphe en vivant** pendant le
  travail, plutôt que de lire un dump — c'est ce qui donne à l'agent une compréhension fine
  du contexte.

`.context/cache/` = sortie graphify (gitignoré). Les directives d'outil de graphify vivent
dans un `CLAUDE.md` isolé.

> Réserve : la *qualité* de la couche sémantique LLM est à éprouver sur un vrai repo avant
> de lui confier l'alimentation de `reference.md`. C'est la seule hypothèse non vérifiée du
> design.

### Repomix — écarté

Repomix fait du *flattening* (concaténation du repo en un blob), utile uniquement pour
donner tout un repo à un modèle **sans** accès au système de fichiers. Dès que l'agent a un
accès vivant au FS + git :

- il noie le signal (dump global vs lecture sélective paresseuse) ;
- il est redondant avec FS + git ;
- il est périmé dès le dump ;
- il **dégrade** la détection de dérive (diffe sur tout le texte, pas sur la structure).

Repomix ne reste qu'un utilitaire d'export ponctuel, hors boucle de pilotage.

---

## 9. Cycle de vie : distillation

La plupart des livrables (specs, roadmaps, reviews, plans de migration, backlogs) ne sont
**pas** des documents persistés : ce sont du working-state ou du transient qui se
**distille** vers les quatre `type` au moment du figeage.

> Les quatre `type` sont les *cibles persistées*. La couche transient/working-state les
> *nourrit* ; c'est le figeage au commit qui distille vers le haut.

Une production ne décide pas « je suis une `reference` » : elle dépose son brouillon dans
`.context/`, et la distillation — proposée par l'IA, validée par l'humain — décide ce qui
mérite de monter. Un plan en cours naît working-state (`.context/`), puis à la complétion
ce qui a *réellement* été décidé est figé en ADR : la transition working-state → daté est
un événement de doc concret.

---

## 10. Bootstrap d'un repo

Toute la convention suppose que la structure existe. Le démarrage est un acte **explicite**,
jamais implicite, en deux scénarios :

- **Repo nu** — un geste d'amorçage pose le squelette vide + `AGENT.md` routeur, puis lance
  le premier passage graphify pour générer le `reference` initial. *Bootstrap = créer le
  contenant, pas le remplir.*
- **Repo avec doc existante** — la doc en vrac est traitée comme **working-state à
  distiller**, déposée dans `.context/`, ingérée par le graphe, puis l'IA *propose* une
  distillation pièce par pièce que l'humain valide. **Jamais** de migration automatique en
  masse, sous peine d'hériter de la dérive de l'ancienne doc.

> La vérité n'entre dans les quatre `type` que par distillation validée, jamais par import
> brut.

