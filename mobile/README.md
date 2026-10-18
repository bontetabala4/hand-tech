# HandTech

Première base de l’application mobile Flutter d’après l’écran utilisateur de
`maquette/handtech_maquette/handtech_interface_utilisateur`.

## Fonctionnalités présentes

- Le contrat actuel du frontend et les consignes de raccordement backend/IA
  sont décrits dans [`docs/BACKEND_INTEGRATION_HANDOFF.md`](docs/BACKEND_INTEGRATION_HANDOFF.md).
- Connexion et déconnexion avec Google Sign-In.
- Accès en mode invité pour essayer les fonctions sans compte.
- Historique local des traductions réservé aux comptes Google connectés ;
  aucune traduction invitée n’est conservée.
- Icônes HandTech pour Android, iOS, Web, Windows et macOS, avec écrans de
  lancement personnalisés sur Android, iOS et Web.
- Aperçu de la caméra et bascule avant/arrière lorsque les deux caméras sont
  disponibles.
- Traduction de texte sur l’appareil avec Google ML Kit (français, anglais,
  espagnol, allemand, italien et portugais) sur Android et iOS. Les modèles
  sont téléchargés au premier usage, puis réutilisés.
- Synthèse vocale du texte traduit, avec réglage de la vitesse.
- Interface disponible en français et en anglais, avec thèmes clair (par
  défaut) et sombre à dominante noire, aqua et bleue.
- La langue et le thème sélectionnés sont enregistrés localement entre les
  lancements de l’application.
- Interface mobile inspirée des couleurs et des cartes de la maquette.

La maquette illustre la reconnaissance LSF, mais aucun modèle ni service de
reconnaissance des signes n’est fourni. La caméra n’affiche donc pas de
transcription prétendument détectée : le raccordement d’un moteur LSF reste à
faire.

Google ML Kit Translation traduit ici du **texte**, pas la LSF, et cette
intégration ne fonctionne que sur Android et iOS. Les modèles sont téléchargés
sur l’appareil au premier usage. Le navigateur et les applications ordinateur
utilisent LibreTranslate via un service backend séparé. Le backend est préparé
dans `backend/translation_api` ; les étapes de déploiement sont décrites plus
bas. La caméra n’envoie encore aucune image : aucun contrat d’API ni moteur de
reconnaissance LSF n’est configuré. Pour brancher ce moteur, il faudra définir
son URL, son mode d’authentification, le format d’entrée (image ou vidéo) et le
format de sortie (transcription, langue et éventuels scores). Les clés de
services doivent rester côté serveur, jamais dans l’application Flutter.

L’historique est conservé localement sur l’appareil, séparé par adresse e-mail
Google, avec un maximum de 100 traductions. Il n’est ni envoyé à Google ni
synchronisé entre appareils. Les traductions réalisées en mode invité ne sont
pas sauvegardées. Comme le moteur de reconnaissance LSF n’est pas encore
connecté, aucun historique de reconnaissance de signes n’est encore créé.

## Traduction Web avec LibreTranslate

Le Web ne peut pas utiliser le plugin mobile Google ML Kit. HandTech accepte
une URL HTTPS `TRANSLATION_API_URL` qui pointe sur le backend LibreTranslate.
Android et iOS continuent d’utiliser ML Kit hors ligne. LibreTranslate est un
moteur distinct ; sa qualité et sa couverture linguistique peuvent différer de
Google Traduction.

Les fichiers Docker lancent LibreTranslate, un petit proxy HTTP de protection
et Caddy pour le HTTPS. Seul Caddy est publié sur Internet ; le service de
traduction et son proxy restent sur le réseau Docker interne. Le proxy limite
les textes à 5 000 caractères, applique un quota par adresse IP et n’autorise
que les origines Web configurées. La limite CORS n’est pas un mécanisme
d’authentification ; ne considérez pas ce déploiement de démonstration comme
une protection anti-abus absolue.

GitHub peut héberger le code et déclencher le déploiement, mais GitHub Pages ne
fait tourner que des sites statiques et les runners GitHub Actions ne sont pas
des serveurs permanents. Pour ne pas laisser le PC allumé, il faut héberger le
conteneur sur une VM cloud. Une VM Oracle Cloud marquée « Always Free » peut
convenir si elle est disponible dans la région ; l’éligibilité et la capacité
ne sont pas garanties, Oracle peut demander une carte pour vérifier le compte
et une mauvaise configuration peut engendrer des frais. Vérifier les limites
de l’offre et configurer un budget avant de continuer. Un sous-domaine DuckDNS
pointant vers l’adresse publique de la VM permet à Caddy d’obtenir le
certificat HTTPS.

### Préparer le serveur cloud

1. Créer une VM Linux éligible à l’offre « Always Free » et vérifier sa
   disponibilité, sa mémoire et les limites de facturation avant de la créer.
2. Réserver/repérer son adresse IP publique, créer un sous-domaine DuckDNS
   pointant vers cette IP et autoriser les entrées TCP sur les ports 80 et 443
   dans les règles réseau de la VM. Ne pas ouvrir les ports 5000 ou 8080 :
   Docker ne les publie pas.
3. Installer Docker Engine avec le plugin Docker Compose sur la VM, puis
   récupérer le projet depuis le dépôt GitHub ou copier le dossier
   `backend/translation_api` sur le serveur.
4. Dans ce dossier, copier `.env.example` vers `.env`. Renseigner `API_DOMAIN`
   avec le sous-domaine DuckDNS et `ALLOWED_ORIGINS` avec l’origine exacte de
   la version Web. Plusieurs origines peuvent être séparées par des virgules ;
   pour le test USB précédent, ajouter `http://127.0.0.1:8765`. Ne pas ajouter
   de chemin ni de barre oblique finale à ces origines.
5. Démarrer les services avec `docker compose up -d --build`. Le premier
   démarrage télécharge les modèles de traduction et peut prendre plusieurs
   minutes. Contrôler les journaux avec `docker compose logs -f`.
6. Vérifier le certificat et le service avec
   `curl https://<API_DOMAIN>/health` ; la réponse attendue est
   `{"status":"ok"}`.

Pour lancer la Web avec le backend, transmettre son URL **publique HTTPS**
au build Flutter :

```powershell
flutter build web --release --no-pub "--dart-define=TRANSLATION_API_URL=https://<API_DOMAIN>/translate"
```

Pour `flutter run`, ajouter le même `--dart-define` à la commande de lancement.
Ne jamais utiliser une URL `http://` publique : le navigateur la bloquerait
depuis la page HTTPS. L’URL est une adresse publique, pas une clé secrète. Les
identifiants DuckDNS, s’il y en a, restent sur le serveur et ne sont jamais
transmis à Flutter.

Le dépôt de ce workspace n’est pas configuré comme dépôt Git. Il faut donc le
publier dans un dépôt GitHub avant de pouvoir le récupérer par `git clone` sur
la VM ; à défaut, copier uniquement le dossier du backend. Aucune VM ni aucun
compte cloud n’a été créé automatiquement.

## Configuration requise

Installer le SDK Flutter 3.44 ou ultérieur. Les projets de plateforme Android,
iOS, Web, Windows, Linux et macOS sont déjà générés dans le dépôt.

### Connexion Google

Dans un même projet Google Cloud, créer un client OAuth **Android** avec
l’identifiant d’application `com.handtech.com` et l’empreinte SHA-1 qui signe
l’application, ainsi qu’un client OAuth **Application Web**. L’application
utilise l’ID public du client Web fourni dans
`src/handtech_OAuth_web.json`. Pour l’APK de
débogage local, obtenir l’empreinte du certificat réellement compilé avec
`C:\AndroidSdk\build-tools\36.1.0\apksigner.bat verify --print-certs build\app\outputs\flutter-apk\app-debug.apk`.
Pour une release, enregistrer également l’empreinte du certificat de
distribution (celle de Play App Signing si l’application est distribuée par
Google Play). Les deux identifiants OAuth sont
différents : Android est associé côté Google au package et au certificat ; sur
Android, le plugin Sign-In exige toutefois l’ID du client Web en
`serverClientId`. Ne pas transmettre l’ID client Android à cette option.

Le code Android utilise cet ID Web comme `serverClientId`. Sur le Web, il
l’utilise comme `clientId` pour le bouton Google Identity Services. L’ID est
public et ne constitue pas un secret. Le fichier
`src/handtech_OAuth_android.json` fourni est de type `installed`, et non un
client OAuth Android natif : son ID n’est pas utilisé par l’application. Le
client Android natif est configuré dans Google Cloud avec le package et le
SHA-1 ; il n’a pas besoin d’être embarqué dans l’application.
Pour iOS et macOS, créer aussi un client natif avec l’identifiant de bundle
`com.handtech.com` et configurer son URL scheme selon les instructions du
plugin. Le nouveau package Android installe une application distincte de
l’ancienne `com.handtech.live` ; désinstaller l’ancienne si elle n’est plus
nécessaire.

L’identifiant Web est configuré dans `lib/google_oauth_config.dart`. Aucun
`--dart-define` ni secret OAuth n’est nécessaire pour démarrer ou compiler les
versions Android et Web :

```powershell
flutter run --release -d web-server --web-hostname 127.0.0.1 --web-port 8765
```

Pour compiler puis installer la version Android sur un téléphone autorisé par
ADB :

```powershell
flutter run --release -d <device-id>
```

Ouvrir ensuite `http://127.0.0.1:8765` dans le navigateur. Pour un autre
appareil, remplacer `web-server` par son identifiant Flutter et utiliser les
identifiants OAuth correspondant à cette plateforme.

Pour le Web, `GOOGLE_CLIENT_ID` doit être un identifiant OAuth **Application
Web**. Ajouter exactement l’origine utilisée au test (par exemple
`http://127.0.0.1:8765`) à **Origines JavaScript autorisées** dans Google Cloud
Console. Ne pas ajouter de chemin ni de barre oblique finale ; ajouter
`http://localhost:8765` séparément si le test utilise `localhost`. Google
Sign-In Web utilise le bouton officiel Google Identity Services. Le plugin Web
n’accepte pas `serverClientId`.

Ne jamais intégrer le secret client Web (`client_secret`) de
`src/handtech_OAuth_web.json` au code Flutter, aux assets ou à un build. Il doit
rester uniquement sur un serveur confidentiel.

## Partager un APK Android

Pour remettre une version de test à un utilisateur Android, créer un APK
release avec `flutter build apk --release`. Le fichier est produit sous
`build/app/outputs/flutter-apk/app-release.apk`. Il peut être envoyé directement
pour une installation manuelle (le téléphone devra autoriser l’installation
d’applications provenant de cette source). Si l’écran de consentement OAuth est
en mode test, l’adresse Google du testeur doit figurer dans les utilisateurs de
test. L’APK release local utilise la clé de signature configurée dans Gradle ;
son empreinte doit être enregistrée dans le client OAuth Android, en plus du
SHA-1 debug si les deux types de builds sont utilisés.

Sur Windows, Flutter requiert le mode développeur ou un terminal administrateur
pour créer les liens symboliques de plugins : ouvrir `start ms-settings:developers`
et activer le mode développeur avant `flutter pub get`.

### Permissions et prérequis natifs

Après avoir généré les plateformes :

- Android : la permission caméra et la déclaration TTS sont configurées dans le
  manifeste.
- iOS : le déploiement minimum est iOS 15.5 et la description d’usage caméra
  est configurée dans `ios/Runner/Info.plist`.

Aucun audio n’est capturé par la caméra.

Les projets sont générés pour Android, iOS, Web, Windows, Linux et macOS. Les
plugins Google ML Kit Translation ne prennent en charge que Android/iOS ;
Google Sign-In est intégré pour Android/iOS/Web/macOS, mais pas Windows/Linux.
La caméra demande également une implémentation native disponible par plateforme.
Les compilations iOS/macOS nécessitent macOS et Xcode ; la compilation Windows
nécessite les outils C++ Desktop de Visual Studio.

Le diagnostic de cette machine signale aussi que le chemin actuel du SDK Android
contient des espaces ; Android Studio/Flutter recommandent un emplacement sans
espaces pour l’outillage NDK.

## Démarrage

Après génération des plateformes :

```powershell
flutter pub get
flutter run
```

La traduction sur appareil est réservée à Android et iOS. Pour démarrer le Web
sur un autre poste ou après avoir arrêté le serveur courant, utiliser la
commande ci-dessus.
