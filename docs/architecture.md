# Architecture technique — Hand Tech

## Flux cible

```
Caméra → Application Flutter → API HTTPS → Backend (FastAPI)
       → Service IA (Python) → prédiction → Backend → Application Flutter
```

Le dispositif matériel pourra ensuite communiquer avec l'application ou le backend
selon le protocole retenu (Bluetooth, Wi-Fi ou USB — décision non prise, cf. section
"Décisions en attente").

## État actuel (M1)

- ✅ Structure du dépôt créée.
- ✅ Backend FastAPI initialisé avec contrat `/api/v1/predictions` **mocké**.
- ✅ Docker + docker-compose pour backend et PostgreSQL.
- ✅ CI GitHub Actions (lint + tests backend).
- ⬜ Service IA (`ai/`) — à initialiser (prochain ticket).
- ⬜ Application Flutter (`mobile/`) — à initialiser.
- ⬜ Étude du dispositif matériel (`hardware/`).

## Contrat API — `POST /api/v1/predictions`

**Requête :**
```json
{
  "image_base64": "<image encodée en base64>",
  "session_id": "optionnel"
}
```

**Réponse :**
```json
{
  "sign": "BONJOUR",
  "confidence": 0.94,
  "timestamp": "2026-09-06T12:00:00Z",
  "mocked": true
}
```

Ce contrat est **versionné** (`/api/v1/`). Toute modification incompatible doit
passer par une nouvelle version (`/api/v2/`) plutôt que casser le contrat existant,
pour ne pas bloquer le Dev Mobile pendant que le Dev IA itère sur le modèle.

## Stockage

- **PostgreSQL** : utilisateurs, sessions, prédictions, paramètres, métadonnées.
- **Hors PostgreSQL** : vidéos, images brutes, datasets, poids de modèles → stockage
  fichier dédié à définir (ex: volume dédié ou stockage objet), jamais en base
  relationnelle.

## Décisions en attente (à valider avant développement complet)

Voir cahier des charges section 27 — notamment : langue des signes cible, liste
exacte des signes du MVP, signes isolés ou séquences, texte seul ou texte+voix,
traitement local ou serveur, protocole du dispositif matériel.

## Historique des décisions structurantes

| Date | Décision | Raison |
|---|---|---|
| 2026-09-06 | Backend en FastAPI (Python) | Cohérence avec le service IA, écosystème Python partagé |
| 2026-09-06 | Endpoint prédiction mocké en premier | Débloquer le Dev Mobile sans attendre le modèle IA |
