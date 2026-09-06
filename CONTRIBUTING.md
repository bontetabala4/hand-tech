# Guide de contribution — Hand Tech

## Branches

- `main` : toujours stable et démontrable.
- `feature/ai-mediapipe` : travail Dev IA.
- `feature/flutter-camera` : travail Dev Mobile.
- `feature/api-prediction` : travail Backend.
- `feature/docker` : infrastructure/Docker.

Convention de nommage : `feature/<sujet>`, `fix/<sujet>`, `docs/<sujet>`.

## Workflow

1. Créer ou prendre un ticket GitHub Issue (un responsable par ticket).
2. Créer une branche depuis `main`.
3. Développer + tester localement.
4. Ouvrir une Pull Request vers `main`, en liant le ticket.
5. Revue de code par au moins une autre personne.
6. Merge puis fermeture du ticket.

## Convention de commits (en français)

Format : `<type>: <description courte>`

Types utilisés :
- `feat` : nouvelle fonctionnalité
- `fix` : correction de bug
- `docs` : documentation uniquement
- `refactor` : changement sans impact fonctionnel
- `test` : ajout ou modification de tests
- `chore` : tâches techniques (dépendances, config, CI)

Exemples :
```
feat: ajouter l'endpoint POST /api/v1/predictions (mocké)
fix: corriger la validation du score de confiance
docs: documenter l'architecture cible dans docs/architecture.md
chore: initialiser la structure du dépôt et le squelette backend
```

## Points d'équipe

- Deux points courts par semaine : planification (début de semaine), revue/blocages (fin de semaine).
- Utiliser GitHub Issues + Projects + labels + milestones pour suivre l'avancement.
