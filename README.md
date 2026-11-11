# Hand Tech

Hand Tech est un projet d'assistance à la communication entre personnes sourdes
ou malentendantes et personnes entendantes, avec pour langue cible la langue des
signes congolaise (LSC).

Le premier produit visé est une application mobile Flutter. Le backend est
développé avec Python et FastAPI.

## État actuel

Le backend fournit actuellement :

- `GET /health` : contrôle de disponibilité.
- `GET /api/v1/auth/me` : lecture de l'identité issue d'un Google ID Token
  vérifié, sous réserve de configurer `GOOGLE_CLIENT_ID`.

**La reconnaissance de la LSC n'est pas encore intégrée.** Aucun endpoint ne
retourne de signe reconnu. Les anciennes prédictions aléatoires ont été retirées :
elles ne représentaient pas une reconnaissance réelle.

L'authentification est un squelette backend : les tests automatisés actuels
simulent la fonction de vérification Google et ne remplacent pas un test
d'intégration avec un véritable ID Token.

## Structure du dépôt

```
hand-tech/
├── mobile/              # Application Flutter existante
├── backend/             # API FastAPI
├── ai/                  # Composant IA à intégrer
├── hardware/            # Étude du dispositif connecté
├── infrastructure/      # Déploiement et infrastructure
├── docs/                # Documentation technique
├── scripts/             # Scripts utilitaires
├── .github/workflows/   # CI/CD
└── docker-compose.yml
```

## Démarrage du backend

À partir de la racine du dépôt :

```bash
cp .env.example .env
docker compose up --build backend db
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
