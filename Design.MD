# Design System & UI/UX Guidelines — Ek Talk Helper (Flutter)
# Architecture : Smart Glasses + Mobile App

## 1. Vision & Direction Artistique
- **Style :** Clean Minimal, High Contrast, Accessible, Dashboard Wearable.
- **Inspirations :** Meta Ray-Ban App, Live Transcribe (Google), Linear.
- **Thème Visuel :** Fond gris neutre équilibré rehaussé par des touches bleu ciel pour une identité tech, claire et moderne.

## 2. Palette de Couleurs & Theme (Color Palette)
- **Primary Background :** `#808080` (Standard Gray / RGB: 128, 128, 128) — Fond principal.
- **Surface / Cards :** `#666666` à `#4D4D4D` — Cartouches et conteneurs pour créer du relief sur le fond gris.
- **Secondary / Accent :** `#38BDF8` ou `#7DD3FC` (Bleu Ciel) — Boutons d'action principaux (FAB), indicateurs d'état actifs, surbrillance du texte.
- **Text Primary :** `#FFFFFF` (Blanc pur) — Pour garantir un contraste maximal sur le fond gris.
- **Text Secondary :** `#E0F2FE` (Blanc teint de bleu) — Pour les sous-titres et légendes.
- **Hardware Status :**
  - Vert Connecté : `#4ADE80`
  - Orange Hors-champ / Alerte : `#FBBF24`
  - Rouge Déconnecté : `#F87171`

## 3. Indicateurs d'État Matériel (Hardware Status Bar)
- **Glass Battery Bar :** Pourcentage de batterie du matériel connecté.
- **Camera Feed Status :** Voyant vert (Caméras actives & cadrage OK), Voyant Orange (Cadrage hors champ / Obstruction).
- **Connectivity Indicator :** État du flux BLE / Wi-Fi Direct.

## 4. Typographie & Accessibilité
- **Live Text Feed :** Police sans-serif ultra-lisible (Roboto / Inter), taille dynamique (28pt à 40pt) en couleur `#FFFFFF` avec mise en évidence des nouveaux mots en Bleu Ciel (`#38BDF8`).
- **Voice Feedback Indicator :** Animation d'onde sonore bleu ciel quand l'audio est transmis vers les lunettes.

## 5. Layouts & Structure des Écrans (Flutter)

### A. Screen: `GlassesDashboardScreen` (Écran Principal)
- **Top Section (`HardwareHeader`) :**
  - Cartouche de statut des lunettes (Batterie, Signal, Caméras 1 & 2) sur fond carte `#666666`.
  - Bouton accès Réglages / Appairage avec icône Bleu Ciel.
- **Center Section (`LiveTranscriptionView`) :**
  - Zone de texte dynamique géante faisant défiler la traduction du signe capté par les lunettes en temps réel.
- **Floating Overlay (`CameraPreviewPip`) :**
  - Petite vignette vidéo rétractable (15% de l'écran) bordée de Bleu Ciel montrant le flux vidéo brut des lunettes.
- **Bottom Section (`AudioControlBar`) :**
  - Switch d'évacuation Audio (Sortie : Lunettes vs Haut-Parleur Téléphone).
  - Bouton Play/Replay de la dernière phrase traduite.
  - FAB central (Bleu Ciel `#38BDF8` avec icône sombre) : Play / Pause de la détection sur les lunettes.

### B. Screen: `GlassesPairingOnboarding`
- Assistants pas-à-pas pour la connexion Bluetooth/Wi-Fi des lunettes.
- Guide d'ajustement des lunettes sur le visage pour un cadrage optimal des mains.

## 6. Directives de Code pour Antigravity
- Appliquer un `ThemeData` personnalisé intégrant `scaffoldBackgroundColor: Color(0FF808080)`.
- Implémenter un **State Management** solide (Riverpod / BLoC) pour réagir aux événements réseau du matériel sans bloquer l'UI.
- Gérer la déconnexion intempestive du périphérique avec une alerte visuelle non intrusive (`SnackBar` / `Banner`).
- Intégrer les retours haptiques (`HapticFeedback`) lors des changements d'état du matériel.