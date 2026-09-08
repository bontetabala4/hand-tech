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
- ✅ Backend FastAPI initialisé avec contrat `/api/v1/predictions` **mocké**
  (le signe reconnu est encore aléatoire, en attendant le modèle IA).
- ✅ Base de données PostgreSQL structurée (users, sessions, predictions) avec
  migrations Alembic — voir Pull Request #1 (`feature/api-prediction`).
- ✅ Chaque prédiction est **réellement enregistrée** en base (plus seulement
  renvoyée) et consultable via `GET /api/v1/predictions` (historique).
- ✅ Docker + docker-compose pour backend et PostgreSQL.
- ✅ CI GitHub Actions (tests backend, sur base SQLite en mémoire — voir note
  ci-dessous).
- ⬜ Service IA (`ai/`) — à initialiser (ticket à créer avec le Dev IA).
- ⬜ Application Flutter (`mobile/`) — ticket EK-020, à faire par le Dev Mobile.
- ⬜ Authentification — pas encore nécessaire pour le MVP (section 19 :
  "lorsque nécessaire"). Utilisateur anonyme unique utilisé en attendant.
- ⬜ Étude du dispositif matériel (`hardware/`).

**Note sur les tests** : les tests backend tournent sur une base SQLite en
mémoire (voir `backend/tests/test_predictions.py`), pas sur le vrai
PostgreSQL. Cela garde la CI rapide et indépendante de l'infrastructure,
tout en validant la même logique applicative (SQLAlchemy abstrait le moteur
de base via le type `GUID` défini dans `app/models/database.py`).

## Contrat API

### `POST /api/v1/predictions`

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

### `GET /api/v1/predictions?limit=50`

Retourne l'historique des prédictions les plus récentes (écran "Historique",
section 9), toutes sessions confondues pour l'instant (MVP mono-utilisateur
anonyme, pas encore d'authentification).

**Réponse :**
```json
[
  {
    "id": "b3f1...",
    "sign": "BONJOUR",
    "confidence": 0.94,
    "mocked": true,
    "created_at": "2026-09-08T01:50:00Z"
  }
]
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
| 2026-09-07 | Type `GUID` maison plutôt que UUID PostgreSQL en dur | Permet de tester sur SQLite en mémoire, sans dépendre d'un vrai PostgreSQL en CI |
| 2026-09-07 | Utilisateur anonyme unique en attendant l'authentification | L'auth n'est pas nécessaire pour le MVP (section 19) ; évite de bloquer la persistance des prédictions |
