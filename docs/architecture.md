# Architecture technique — Hand Tech

## Périmètre et principes

Hand Tech vise à faciliter la communication entre personnes sourdes ou
malentendantes et personnes entendantes dans le contexte congolais.

- Langue cible : langue des signes congolaise (LSC).
- Premier produit : application mobile Flutter.
- Périmètre du Tech Lead : backend et base de données.
- Le frontend mobile existant reste intact sans décision explicite de coordination.
- Aucune reconnaissance ne doit être simulée : pas de signe aléatoire, de score
  fictif, de dataset inventé ni de modèle fictif.

## État réel du backend

- FastAPI avec authentification Google ID Token côté backend.
- PostgreSQL avec SQLAlchemy et migrations Alembic.
- Modèle utilisateur lié au claim Google `sub` vérifié.
- Historique textuel privé : source, traduction, langues et date.
- Routes de création, consultation paginée et suppression de l'historique.
- Les vidéos et images caméra ne sont pas stockées dans PostgreSQL.
- Aucun moteur ou modèle de reconnaissance LSC n'est intégré.
- Aucun flux vidéo caméra n'est encore connecté au backend.

Les tests d'authentification actuels remplacent la vérification Google par un
mock au niveau du test. Ils ne prouvent pas encore l'intégration avec un véritable
jeton Google. Le client mobile doit envoyer l'ID Token dans l'en-tête
`Authorization: Bearer <id_token>` pour appeler les routes privées.

## Données et règles de confidentialité

### `users`

- Identifiant interne UUID.
- `google_sub` : identifiant externe Google stable, unique et vérifié.
- Email et indicateur de vérification, issus des claims vérifiés.
- Dates de création et de mise à jour.

### `translation_history`

- Identifiant interne UUID.
- Référence à l'utilisateur propriétaire avec suppression en cascade.
- Texte source et texte traduit (5 000 caractères maximum chacun à l'API).
- Langue source, langue cible et date de création.

Chaque lecture et suppression filtre par l'utilisateur authentifié. Un utilisateur
ne peut donc pas consulter ni supprimer les entrées d'un autre utilisateur via
les routes prévues. L'utilisateur peut supprimer une entrée ou tout son historique.

Aucune vidéo, image, séquence brute, donnée biométrique ou score de reconnaissance
n'est enregistrée dans ces tables. La durée de conservation et les mécanismes
d'export devront être définis avant la mise en production.

## Architecture cible de reconnaissance

Le flux visé est une capture vidéo continue depuis Flutter, un transport média
adapté, un traitement temporel par un véritable moteur de reconnaissance LSC,
puis le retour progressif du texte reconnu vers l'application.

1. **Flutter** : capture et affichage caméra, gestion de l'interface et réception
   des résultats.
2. **Backend FastAPI** : authentification, autorisation, gestion des sessions,
   orchestration et accès aux données.
3. **Transport média** : mécanisme à choisir avec l'équipe mobile.
4. **Moteur de reconnaissance** : composant réel, versionné et évalué sur des
   données LSC autorisées et représentatives.
5. **Canal de résultats** : mécanisme à choisir pour transmettre les résultats
   partiels et finaux.
6. **PostgreSQL** : comptes, historique textuel et métadonnées autorisées.

WebRTC et WebSocket sont des options à évaluer, pas des décisions validées.
Les paramètres vidéo, le contrat d'événements, la latence et la reconnexion
restent à définir avec l'équipe mobile et l'équipe IA.

## Migrations et commandes

Depuis le dossier `backend` (dans le conteneur ou un environnement ayant accès
à PostgreSQL) :

- Appliquer : `alembic upgrade head`
- Créer une migration après modification des modèles :
  `alembic revision --autogenerate -m "description"`
- Revenir à la migration précédente : `alembic downgrade -1`

Les migrations doivent être relues avant application sur une base de production.

## Décisions techniques encore ouvertes

- Transport vidéo et protocole de retour des événements.
- Format, codec, résolution et fréquence d'images.
- Création, expiration et fermeture des sessions.
- Schéma des événements partiels, finaux, incertains et sans signe détecté.
- Authentification du canal média et renouvellement des jetons.
- Reconnexion, contrôle de flux, latence et gestion des erreurs.
- Politique de conservation des médias et consentement.
- Interface entre backend et moteur IA.
- Mesures de performance et protocole d'évaluation LSC.

Ces paramètres ne doivent pas être inventés : ils seront définis à partir des
contraintes réelles du frontend, du modèle et de l'infrastructure.
