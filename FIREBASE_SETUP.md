# Configuration Firebase pour GymAI

## Option 1 : FlutterFire CLI (Recommandé)

### 1. Installer FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Se connecter à Firebase
```bash
firebase login
```

### 3. Configurer le projet automatiquement
```bash
flutterfire configure
```
Cette commande va :
- Créer un projet Firebase (ou utiliser un existant)
- Générer les fichiers de configuration pour iOS et Android
- Créer automatiquement `firebase_options.dart`

### 4. Modifier main.dart pour utiliser les options générées
Remplacer :
```dart
await Firebase.initializeApp();
```

Par :
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 5. Activer les services dans la console Firebase
1. Aller sur https://console.firebase.google.com
2. Sélectionner ton projet
3. Activer **Authentication** > Email/Password
4. Activer **Firestore Database** (mode test pour commencer)
5. Activer **Storage** (mode test pour commencer)

---

## Option 2 : Configuration Manuelle

### Pour Android

1. **Console Firebase** :
   - Créer un projet Firebase
   - Ajouter une application Android
   - Package name : `com.example.gymai` (vérifier dans `android/app/build.gradle`)
   - Télécharger `google-services.json`

2. **Placer le fichier** :
   ```
   android/app/google-services.json
   ```

3. **Modifier android/build.gradle** :
   ```gradle
   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
     }
   }
   ```

4. **Modifier android/app/build.gradle** :
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### Pour iOS

1. **Console Firebase** :
   - Ajouter une application iOS
   - Bundle ID : `com.example.gymai` (vérifier dans `ios/Runner.xcodeproj`)
   - Télécharger `GoogleService-Info.plist`

2. **Placer le fichier** :
   - Ouvrir `ios/Runner.xcworkspace` dans Xcode
   - Glisser-déposer `GoogleService-Info.plist` dans le dossier Runner
   - Cocher "Copy items if needed"

3. **Installer les pods** :
   ```bash
   cd ios
   pod install
   cd ..
   ```

---

## Règles Firestore (Important pour la sécurité)

Dans la console Firebase > Firestore Database > Rules :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == userId;
    }

    // Posts collection
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;

      // Likes subcollection
      match /likes/{likeId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
  }
}
```

## Règles Storage (Important pour les photos)

Dans la console Firebase > Storage > Rules :

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /posts/{userId}/{postId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Tester la configuration

Après la configuration, lance l'app :

```bash
# Android
flutter run

# iOS
flutter run -d ios
```

L'app devrait :
1. Afficher la page de login
2. Permettre de créer un compte
3. Se connecter automatiquement après signup
4. Afficher la page d'onboarding puis le feed

---

## Troubleshooting

### Erreur "No Firebase App"
- Vérifier que `Firebase.initializeApp()` est appelé dans main.dart
- Vérifier que les fichiers de config sont au bon endroit

### Erreur de permissions Firestore
- Vérifier les règles Firestore dans la console
- En mode développement, tu peux temporairement utiliser :
  ```
  allow read, write: if request.auth != null;
  ```

### iOS ne compile pas
- Vérifier que les pods sont installés : `cd ios && pod install`
- Nettoyer le build : `flutter clean && flutter pub get`
- Mettre à jour les pods : `cd ios && pod update`

### Android ne compile pas
- Vérifier que google-services.json est dans android/app/
- Vérifier les classpath dans les build.gradle
- Nettoyer le build : `flutter clean && flutter pub get`
