# Hand Tech

Application mobile + Intelligence artificielle + Dispositif connecté pour faciliter la communication entre personnes sourdes/malentendantes et personnes entendantes, par reconnaissance de la langue des signes.

## État du projet

🚧 **Phase actuelle : M1 — Architecture, GitHub et environnements** (voir [docs/architecture.md](docs/architecture.md))

Le backend expose pour l'instant un contrat **mocké** : `POST /api/v1/predictions` retourne un signe aléatoire parmi une liste temporaire, en attendant le modèle IA (ticket EK-012 et suivants).

## Structure du dépôt

```
hand-tech-project/
├── mobile/            # Application Flutter
├── backend/           # API FastAPI
├── ai/                # Service de reconnaissance IA (Python)
├── hardware/          # Étude et prototype du dispositif matériel
├── infrastructure/    # Déploiement, configuration serveurs
├── docs/              # Documentation technique
├── scripts/           # Scripts utilitaires
├── .github/workflows/ # CI/CD
└── docker-compose.yml
```

## Démarrage rapide (backend)

```bash
cp .env.example .env
docker compose up --build backend db
```

L'API est disponible sur `http://localhost:8000`. Documentation interactive : `http://localhost:8000/docs`.

Test rapide :

```bash
curl -X POST http://localhost:8000/api/v1/predictions \
  -H "Content-Type: application/json" \
  -d '{"image_base64": "ZmFrZQ=="}'
```

## Lancer les tests backend

```bash
cd backend
pip install -r requirements.txt
pytest -v
```

## Documentation

- [Architecture technique](docs/architecture.md)
- [Guide de contribution](CONTRIBUTING.md)

## Équipe

| Rôle | Responsabilités |
|---|---|
| Tech Lead / Backend | Architecture, API, GitHub, Docker, CI/CD, documentation |
| Dev IA | Dataset, MediaPipe/OpenCV, entraînement, service de prédiction |
| Dev Mobile | Flutter, UI, caméra, intégration API |
| Hardware | Étude et prototype du dispositif connecté |
