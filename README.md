# Hand Tech

Hand Tech est un projet d'assistance à la communication entre personnes sourdes
ou malentendantes et personnes entendantes, avec pour langue cible la langue des
signes congolaise (LSC).

Le premier produit visé est une application mobile Flutter. Le backend est
développé avec Python, FastAPI, SQLAlchemy, Alembic et PostgreSQL.

## État actuel du backend

- `GET /health` : contrôle de disponibilité.
- `POST /translate` : traduction textuelle compatible avec le client Flutter,
  via un service LibreTranslate configuré côté serveur.
- `GET /api/v1/auth/me` : lecture de l'identité issue d'un Google ID Token
  vérifié, sous réserve de configurer `GOOGLE_CLIENT_ID`.
- `POST /api/v1/translations` : enregistrement d'une traduction textuelle
  authentifiée.
- `GET /api/v1/translations` : consultation paginée de l'historique personnel.
- `DELETE /api/v1/translations/{entry_id}` : suppression d'une entrée personnelle.
- `DELETE /api/v1/translations` : suppression de tout l'historique personnel.

L'historique conserve uniquement le texte source, le texte traduit, les codes de
langue et la date. Les vidéos et images de caméra ne sont pas enregistrées.
Chaque entrée est isolée par utilisateur authentifié.

### Configuration de la traduction

Renseigner dans le fichier serveur `.env` :

- `LIBRETRANSLATE_URL` : URL de base du service LibreTranslate, sans le suffixe
  `/translate`.
- `LIBRETRANSLATE_API_KEY` : clé facultative si l'instance l'exige.
- `TRANSLATION_TIMEOUT_SECONDS` : délai maximal, 30 secondes par défaut.

La route accepte les langues `de`, `en`, `es`, `fr`, `it` et `pt`, et
limite le texte à 5 000 caractères. Si LibreTranslate n'est pas configuré ou
indisponible, l'API renvoie une erreur 503 explicite : elle ne fabrique jamais
une traduction.

Pour Flutter Web, renseigner `CORS_ALLOWED_ORIGINS` avec les origines exactes
autorisées, au format JSON, par exemple
`["https://app.example.org"]`. Ne pas utiliser `*` en production.

**La reconnaissance de la LSC n'est pas encore intégrée.** Aucun endpoint ne
retourne de signe reconnu. Les anciennes prédictions aléatoires ont été retirées :
elles ne représentaient pas une reconnaissance réelle.

L'authentification est un squelette backend : les tests automatisés actuels
simulent la fonction de vérification Google et ne remplacent pas un test
d'intégration avec un véritable ID Token. Le mobile doit encore envoyer le
Google ID Token dans l'en-tête Bearer avant d'utiliser les routes privées.

## Structure du dépôt

```
hand-tech/
├── mobile/              # Application Flutter existante
├── backend/             # API FastAPI, SQLAlchemy et migrations Alembic
├── ai/                  # Composant IA à intégrer
├── hardware/            # Étude du dispositif connecté
├── infrastructure/      # Déploiement et infrastructure
├── docs/                # Documentation technique
├── scripts/             # Scripts utilitaires
├── .github/workflows/   # CI/CD
└── docker-compose.yml
```

## Démarrage et migrations

À partir de la racine du dépôt :

```bash
cp .env.example .env
docker compose up -d db
docker compose run --build --rm backend alembic upgrade head
docker compose up -d backend
```

L'API est prévue sur `http://localhost:8000`. Documentation interactive :
`http://localhost:8000/docs`.

Pour exécuter les tests localement :

```bash
cd backend
python -m pip install -r requirements.txt
pytest -v
```

Utiliser Python 3.12 pour l'environnement local actuel.

## Documentation

- [Architecture technique](docs/architecture.md)
- [Guide de contribution](CONTRIBUTING.md)

## Responsabilités de l'équipe

| Rôle | Responsabilités |
|---|---|
| Tech Lead / Backend | Architecture backend, API, base de données, GitHub, Docker et documentation |
| IA | Dataset autorisé, modèle LSC, entraînement, évaluation et service de reconnaissance |
| Mobile | Flutter, interface, caméra et intégration API |
| Hardware | Étude et développement du dispositif connecté |
