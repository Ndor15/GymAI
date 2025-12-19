# Configuration Firebase Manuelle pour Windows

## Étape 1 : Créer le projet Firebase

1. Va sur https://console.firebase.google.com
2. Clique sur "Ajouter un projet"
3. Nom du projet : **GymAI** (ou ce que tu veux)
4. Accepte les conditions et clique "Continuer"
5. Désactive Google Analytics (optionnel pour l'instant)
6. Clique "Créer le projet"

---

## Étape 2 : Activer les services

### Authentication
1. Dans le menu de gauche, clique sur **Build > Authentication**
2. Clique sur "Commencer"
3. Dans l'onglet **Sign-in method**, active **"Email/Password"**
4. Clique sur "Enregistrer"

### Firestore Database
1. Dans le menu de gauche, clique sur **Build > Firestore Database**
2. Clique sur "Créer une base de données"
3. Choisis **"Commencer en mode test"** (pour développement)
4. Sélectionne une région proche de toi (ex: **europe-west1**)
5. Clique sur "Activer"

### Storage
1. Dans le menu de gauche, clique sur **Build > Storage**
2. Clique sur "Commencer"
3. Choisis **"Commencer en mode test"**
4. Clique sur "Suivant" puis "OK"

---

## Étape 3 : Configurer Android

### 3.1 Trouver le package name
Ouvre `android/app/build.gradle` et trouve cette ligne :
```gradle
applicationId "com.example.gymai"
```
Note ce package name (probablement `com.example.gymai`)

### 3.2 Ajouter une app Android dans Firebase
1. Dans la console Firebase, clique sur l'icône **Android** (en haut)
2. Package name : `com.example.gymai` (celui trouvé ci-dessus)
3. App nickname : **GymAI Android** (optionnel)
4. Clique sur "Enregistrer l'application"

### 3.3 Télécharger google-services.json
1. Télécharge le fichier `google-services.json`
2. Place-le dans : **`android/app/google-services.json`**

### 3.4 Modifier les fichiers Gradle

**Fichier : `android/build.gradle`**

Ajoute cette ligne dans `dependencies` (dans le bloc `buildscript`) :
```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.1'
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10'
        classpath 'com.google.gms:google-services:4.4.0'  // <-- AJOUTE CETTE LIGNE
    }
}
```

**Fichier : `android/app/build.gradle`**

À la toute fin du fichier, ajoute :
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## Étape 4 : Configurer iOS (si tu testes sur iPhone)

### 4.1 Trouver le Bundle ID
Ouvre `ios/Runner.xcodeproj` dans Xcode et regarde le Bundle Identifier (probablement `com.example.gymai`)

Ou regarde dans `ios/Runner/Info.plist`

### 4.2 Ajouter une app iOS dans Firebase
1. Dans la console Firebase, clique sur l'icône **iOS** (en haut)
2. Bundle ID : `com.example.gymai`
3. App nickname : **GymAI iOS** (optionnel)
4. Clique sur "Enregistrer l'application"

### 4.3 Télécharger GoogleService-Info.plist
1. Télécharge le fichier `GoogleService-Info.plist`
2. Ouvre `ios/Runner.xcworkspace` dans **Xcode**
3. Glisse-dépose le fichier `GoogleService-Info.plist` dans le dossier **Runner**
4. Coche **"Copy items if needed"**

### 4.4 Installer les Pods
Ouvre un terminal et lance :
```bash
cd ios
pod install
cd ..
```

---

## Étape 5 : Créer firebase_options.dart manuellement

Créer le fichier **`lib/firebase_options.dart`** avec ce contenu :

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // COPIE LES VALEURS DEPUIS google-services.json (Android)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIza...', // Depuis "current_key" dans google-services.json
    appId: '1:...:android:...', // Depuis "mobilesdk_app_id" dans google-services.json
    messagingSenderId: '...', // Depuis "project_number" dans google-services.json
    projectId: 'gymai-...', // Depuis "project_id" dans google-services.json
    storageBucket: 'gymai-....appspot.com', // Depuis "storage_bucket" dans google-services.json
  );

  // COPIE LES VALEURS DEPUIS GoogleService-Info.plist (iOS)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIza...', // Depuis "API_KEY" dans GoogleService-Info.plist
    appId: '1:...:ios:...', // Depuis "GOOGLE_APP_ID" dans GoogleService-Info.plist
    messagingSenderId: '...', // Depuis "GCM_SENDER_ID" dans GoogleService-Info.plist
    projectId: 'gymai-...', // Depuis "PROJECT_ID" dans GoogleService-Info.plist
    storageBucket: 'gymai-....appspot.com', // Depuis "STORAGE_BUCKET" dans GoogleService-Info.plist
    iosBundleId: 'com.example.gymai', // Depuis "BUNDLE_ID" dans GoogleService-Info.plist
  );
}
```

### Comment trouver les valeurs ?

**Pour Android** - Ouvre `android/app/google-services.json` :
```json
{
  "project_info": {
    "project_number": "123456789",        ← messagingSenderId
    "project_id": "gymai-xxxxx",         ← projectId
    "storage_bucket": "gymai-xxxxx.appspot.com"  ← storageBucket
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123:android:abc"  ← appId
      },
      "api_key": [
        {
          "current_key": "AIzaSy..."      ← apiKey
        }
      ]
    }
  ]
}
```

**Pour iOS** - Ouvre `ios/Runner/GoogleService-Info.plist` :
```xml
<key>API_KEY</key>
<string>AIzaSy...</string>        ← apiKey

<key>GOOGLE_APP_ID</key>
<string>1:123:ios:abc</string>   ← appId

<key>GCM_SENDER_ID</key>
<string>123456789</string>       ← messagingSenderId

<key>PROJECT_ID</key>
<string>gymai-xxxxx</string>     ← projectId

<key>STORAGE_BUCKET</key>
<string>gymai-xxxxx.appspot.com</string>  ← storageBucket

<key>BUNDLE_ID</key>
<string>com.example.gymai</string>  ← iosBundleId
```

---

## Étape 6 : Modifier lib/main.dart

Ajoute l'import en haut :
```dart
import 'firebase_options.dart';
```

Modifie la ligne 11 :
```dart
// AVANT
await Firebase.initializeApp();

// APRÈS
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Étape 7 : Configurer les règles de sécurité

### Firestore Rules
Console Firebase > Firestore Database > Règles

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
      match /likes/{likeId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

Clique sur "Publier"

### Storage Rules
Console Firebase > Storage > Règles

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /posts/{userId}/{postId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

Clique sur "Publier"

---

## Étape 8 : Tester

### Sur Android (depuis Windows)
```bash
flutter run
```

### Sur iOS (nécessite un Mac)
```bash
cd ios && pod install && cd ..
flutter run -d ios
```

---

## ⚠️ Important

- **NE PAS** tester sur Windows (Firebase ne compile pas sur Windows)
- Utilise un **émulateur Android** ou un **appareil Android réel**
- Pour iOS, il faut un Mac avec Xcode

---

## Vérification

L'app devrait :
1. ✅ Démarrer sans erreur
2. ✅ Afficher la page de Login
3. ✅ Permettre de créer un compte
4. ✅ Te connecter automatiquement
5. ✅ Afficher l'onboarding puis le feed

Si tu as des erreurs, vérifie :
- Les fichiers de config sont au bon endroit
- Les valeurs dans `firebase_options.dart` sont correctes
- Les règles Firestore/Storage sont publiées
