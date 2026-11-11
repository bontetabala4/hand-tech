# Architecture technique — Hand Tech

## Périmètre et principes

Hand Tech vise à faciliter la communication entre personnes sourdes ou
malentendantes et personnes entendantes, dans le contexte congolais.

- Langue cible : langue des signes congolaise (LSC).
- Premier produit : application mobile Flutter.
- Périmètre du Tech Lead : backend et base de données.
- Le frontend mobile existant doit rester intact sans décision explicite de
  coordination avec l'équipe mobile.
- Aucune reconnaissance ne doit être simulée : pas de signe aléatoire, de score
  de confiance fictif, de dataset inventé ni de modèle fictif.
- Une reconnaissance ne pourra être annoncée comme fonctionnelle qu'après
  intégration et validation d'un véritable modèle LSC sur des données autorisées
  et représentatives.

## État réel du dépôt

- Backend FastAPI initialisé.
- Route de contrôle `GET /health`.
- Squelette d'authentification Google ID Token côté backend :
  `GET /api/v1/auth/me`.
- La vérification Google nécessite la configuration de `GOOGLE_CLIENT_ID`.
- Les tests automatisés de l'authentification utilisent actuellement une
  vérification simulée par monkeypatch ; ils ne constituent pas une validation
  avec un véritable jeton Google.
- PostgreSQL et Docker Compose sont présents dans le dépôt, mais le schéma
  applicatif, les modèles de données et les migrations doivent encore être
  audités et construits.
- Aucun flux vidéo caméra n'est encore connecté au backend.
- Aucun moteur ou modèle de reconnaissance LSC n'est intégré.
- Aucun endpoint de prédiction n'est exposé actuellement.

## Architecture cible à concevoir

Le flux visé est une capture vidéo continue depuis Flutter, un transport média
adapté, un traitement temporel par un véritable moteur de reconnaissance LSC,
puis le retour progressif du texte reconnu vers l'application.

Les responsabilités envisagées sont :

1. **Flutter** : capture et affichage caméra, gestion de l'interface et réception
   des résultats.
2. **Backend FastAPI** : authentification, autorisation, gestion des sessions,
   orchestration et accès aux données.
3. **Transport média** : mécanisme à choisir pour acheminer le flux vidéo.
4. **Moteur de reconnaissance** : composant réel, versionné et évalué, capable
   d'analyser des séquences temporelles de LSC.
5. **Canal de résultats** : mécanisme à choisir pour transmettre les résultats
   partiels et finaux.
6. **PostgreSQL** : données de compte, sessions et métadonnées autorisées par la
   politique de confidentialité.

WebRTC et WebSocket sont des options à évaluer, pas des décisions déjà validées.
Aucun contrat de streaming ne doit être considéré comme définitif avant accord
avec l'équipe mobile et validation technique.

## Décisions techniques à prendre avant le streaming

- Transport vidéo et protocole de retour des événements.
- Format, codec, résolution et fréquence d'images.
- Création, expiration et fermeture des sessions.
- Schéma des événements partiels, finaux, incertains et sans signe détecté.
- Authentification du canal média et renouvellement des jetons.
- Reconnexion, contrôle de flux, latence et gestion des erreurs.
- Politique de conservation, stockage et suppression des vidéos.
- Interface entre backend et moteur IA.
- Mesures de performance et protocole d'évaluation du modèle LSC.

Ces paramètres ne doivent pas être inventés : ils seront définis avec les
contraintes réelles du frontend, du modèle et de l'infrastructure.

## Sécurité et confidentialité

- Vérifier côté serveur les ID Tokens Google : signature, émetteur, expiration
  et audience.
- Utiliser le claim Google `sub` vérifié comme identifiant externe stable.
- Ne jamais faire confiance à un email ou identifiant utilisateur fourni
  librement par le client.
- Ne jamais embarquer de secrets backend ou de clés de fournisseur IA dans
  l'application Flutter.
- Ne pas conserver de vidéo ou d'image brute sans décision explicite de
  confidentialité, de durée de conservation et de consentement.

## Base de données

PostgreSQL est prévu pour les données structurées. Le schéma et les migrations
Alembic restent à mettre en place après validation des entités et des règles de
conservation. Les médias bruts et artefacts de modèles ne doivent pas être
stockés dans des colonnes relationnelles sans décision d'architecture dédiée.

## Historique des décisions

| Sujet | État |
|---|---|
| Backend | FastAPI / Python |
| Base de données cible | PostgreSQL |
| Langue cible | LSC |
| Premier produit | Application mobile |
| Reconnaissance vidéo réelle | Non intégrée |
| Transport vidéo | À décider |
| Canal de résultats progressifs | À décider |
| Modèle et dataset LSC | À fournir, intégrer et évaluer |
