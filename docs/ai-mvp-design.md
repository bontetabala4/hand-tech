# Conception technique — MVP IA de reconnaissance des signes

## 1. Objet et périmètre de l’étude

Ce document cadre une étude de faisabilité pour le MVP de reconnaissance de
signes de Hand Tech. Il compare deux approches :

- **signes isolés** : une image ou une courte capture contenant un seul signe ;
- **signes dynamiques** : une séquence temporelle contenant un signe réalisé
  avec mouvement.

L’étude ne présume d’aucun jeu de données, modèle entraîné, ni vocabulaire de
signes validé. La langue des signes cible et la liste exacte des signes du MVP
restent des décisions produit à obtenir avant tout entraînement ou toute mesure
de performance représentative.

## 2. Objectifs du MVP IA

1. Déterminer si une reconnaissance fiable peut être démontrée sur un
   périmètre de signes explicitement validé.
2. Identifier l’approche qui apporte le meilleur compromis entre qualité,
   expérience mobile, latence, complexité d’intégration et coût de collecte.
3. Préserver une frontière API stable entre l’application Flutter, le backend
   FastAPI et le futur service IA.
4. Éviter toute réponse présentée comme une reconnaissance réelle tant qu’un
   service IA évalué n’est pas intégré.

## 3. Hypothèses de travail à vérifier

| Sujet | Hypothèse à tester | Conséquence si elle est invalidée |
|---|---|---|
| Cadre de capture | La caméra mobile fournit des images ou séquences exploitables dans des conditions réalistes. | Adapter les consignes de capture, la qualité minimale ou le périmètre MVP. |
| Variabilité | Le système doit supporter des personnes, mains, arrière-plans, éclairages et appareils différents. | Collecter des exemples plus diversifiés ou limiter explicitement le contexte d’usage. |
| Signe isolé | Un seul instant ou une courte fenêtre suffit à distinguer le signe retenu. | Privilégier une approche dynamique pour ce signe. |
| Signe dynamique | L’information temporelle améliore effectivement la distinction entre signes. | Ne pas supporter la vidéo pour le MVP si le gain ne justifie pas son coût. |
| Traitement | Le traitement pourra être réalisé par un service IA distinct du backend. | Réexaminer la cible d’exécution sans modifier le contrat public avant décision. |

## 4. Comparaison des options

| Critère | Signes isolés | Signes dynamiques |
|---|---|---|
| Entrée principale | Image/frame unique, compatible avec le contrat actuel. | Séquence de frames ou vidéo ; le contrat actuel ne la décrit pas. |
| Information disponible | Forme et position visibles à l’instant capturé. | Forme, position et évolution du geste dans le temps. |
| Capture côté mobile | Déclenchement simple ; retour potentiellement plus rapide. | Début/fin de capture, durée, cadence et retour d’état à définir. |
| Données à collecter | Exemples annotés de chaque signe dans des conditions variées. | Séquences annotées, avec repères temporels et conditions de capture documentées. |
| Annotation | Libellé validé du signe et métadonnées de capture. | Même annotation, plus les bornes de séquence et la qualité de l’exécution. |
| Complexité IA | Étude initiale plus simple. | Étude plus complexe : préparation et exploitation de la dimension temporelle. |
| Risque fonctionnel | Des signes semblables visuellement peuvent être confondus. | Sensible aux variations de vitesse, de durée et de début/fin de geste. |
| Impact API | Peut être testé sans changer `POST /api/v1/predictions`. | Nécessite un contrat explicite de séquence, donc une évolution versionnée si incompatible. |

Cette comparaison ne conclut pas que l’une des deux options est meilleure de
manière générale. Le choix dépendra du vocabulaire validé, des résultats du
protocole ci-dessous et des contraintes d’expérience mobile.

## 5. Données à collecter avant entraînement

La collecte doit être planifiée après validation de la langue des signes cible
et du vocabulaire du MVP. Elle doit définir, sans créer ni supposer de données
existantes :

- les signes et libellés validés par les personnes compétentes désignées par le
  projet ;
- le type de capture selon l’option : images pour l’isolé, séquences pour le
  dynamique ;
- des participants et contextes assez variés pour mesurer la généralisation,
  sans promettre un seuil non encore établi ;
- les métadonnées strictement nécessaires à l’évaluation : identifiant
  pseudonymisé de participant, conditions de capture, appareil, libellé et,
  pour les séquences, bornes temporelles ;
- une séparation par participant entre jeux de développement et de test, afin
  d’éviter d’évaluer le système sur les mêmes personnes que celles vues lors de
  sa conception ;
- une règle d’exclusion des captures inutilisables et une traçabilité des
  corrections d’annotation.

Les fichiers bruts (images et vidéos), jeux de données et futurs poids de
modèles ne doivent pas être placés dans PostgreSQL. Cette règle est cohérente
avec l’architecture existante, qui réserve la base relationnelle aux données
applicatives et prévoit un stockage fichier dédié à définir.

## 6. Consentement, confidentialité et gouvernance

Les images et vidéos de mains peuvent constituer des données personnelles et
doivent être traitées avec précaution. Avant la collecte, définir :

- une information claire et un consentement explicite, couvrant la finalité de
  recherche/développement, les catégories de données, la durée de conservation,
  les accès et les modalités de retrait ;
- la possibilité de refuser ou retirer son consentement sans conséquence pour
  l’utilisation de l’application, lorsque ce cadre est applicable ;
- la minimisation : collecter uniquement les éléments nécessaires et éviter de
  capturer le visage, l’arrière-plan ou l’audio si non requis ;
- la pseudonymisation des participants et la séparation des tables de liaison
  éventuelles des données de capture ;
- des accès limités au personnel autorisé, des emplacements de stockage définis
  et une politique de suppression à l’issue de la durée convenue ;
- la vérification des obligations juridiques et organisationnelles applicables
  avant toute collecte réelle.

## 7. Protocole de test comparatif

### 7.1 Préparation

1. Faire valider la langue et le vocabulaire du MVP.
2. Formaliser le guide de capture et la grille d’annotation.
3. Obtenir les consentements avant toute acquisition.
4. Constituer des jeux d’étude séparés par participant : développement,
   validation et test final.

### 7.2 Exécution

Pour chaque signe validé, collecter les captures nécessaires dans les deux
modalités lorsque le signe le permet. Évaluer les options sur le même périmètre
fonctionnel, avec des participants et conditions de test non utilisés pour le
réglage. Prévoir des cas représentatifs de variabilité (éclairage, fond,
orientation, appareil et rythme de réalisation) documentés dans le protocole.

Le test doit aussi inclure des entrées hors vocabulaire ou de qualité
insuffisante. Le comportement attendu — refus, message d’incertitude ou absence
de résultat — devra être défini avant l’essai ; il ne faut pas forcer un libellé
de signe lorsque la confiance n’est pas suffisante.

### 7.3 Restitution

Produire un rapport comparatif traçable : version du jeu de test, règles
d’annotation, périmètre, résultats par signe, erreurs observées, latence de
bout en bout et limites connues. Les résultats ne doivent être généralisés ni à
une langue ni à un public au-delà du périmètre effectivement étudié.

## 8. Critères de comparaison et seuils de décision

Les mesures suivantes doivent être calculées sur le jeu de test séparé :

- taux de reconnaissance global et par signe ;
- matrice de confusion, afin d’identifier les signes confondus ;
- taux de rejet ou d’absence de réponse sur les entrées incertaines ;
- latence de bout en bout, de la capture mobile à la réponse ;
- stabilité selon les participants et conditions de capture documentées ;
- effort de collecte, annotation, exploitation et intégration mobile ;
- conformité aux exigences de consentement, confidentialité et conservation.

Les seuils numériques d’acceptation ne sont volontairement pas fixés dans ce
document : ils doivent être validés par le produit et les parties prenantes
avant le test, car ni le vocabulaire ni le contexte d’usage ne sont encore
arrêtés.

## 9. Compatibilité avec l’API actuelle

L’API actuelle expose `POST /api/v1/predictions` avec :

```json
{
  "image_base64": "<image JPEG/PNG encodée en base64>",
  "session_id": "optionnel"
}
```

Elle renvoie volontairement `HTTP 503` tant qu’aucun service de reconnaissance
réel n’est intégré. Le schéma de succès existant prévoit `sign`, `confidence`,
`timestamp` et `mocked`, mais aucun résultat de succès ne doit être produit
avant intégration et évaluation du service IA.

Conséquences par option :

- **isolé** : l’entrée image est compatible pour une expérimentation technique,
  sous réserve que le contrat final de sortie et le comportement en cas
  d’incertitude soient validés ;
- **dynamique** : une séquence n’est pas représentable de façon explicite par
  le contrat actuel. Toute nouvelle structure (vidéo, liste de frames,
  identifiant d’upload ou paramètres temporels) doit être conçue puis livrée via
  une version d’API compatible ou une nouvelle version, conformément à
  `docs/architecture.md`. Elle ne doit pas casser `/api/v1/` pendant les
  itérations IA.

Le futur service IA peut rester séparé du backend, comme le prévoit le
placeholder `ai-service` de Docker Compose. Son protocole interne, son mode de
stockage et sa cible d’exécution restent à définir après l’étude.

## 10. Décision à prendre après l’étude

Après le protocole, organiser une revue réunissant produit, mobile, backend,
IA et les référents compétents pour le vocabulaire. La décision documentée doit
indiquer :

1. le vocabulaire et la langue effectivement retenus ;
2. l’option choisie — isolé, dynamique, ou périmètre réduit nécessitant une
   étude complémentaire ;
3. les résultats et limites qui motivent ce choix ;
4. les exigences de capture et de confidentialité à intégrer ;
5. le plan de compatibilité API et, si nécessaire, la version à créer ;
6. les critères de passage à l’intégration du service IA réel.

Tant que cette décision n’est pas prise et qu’un service évalué n’est pas
branché, l’endpoint doit conserver son comportement explicite d’indisponibilité
et ne pas simuler de reconnaissance.
