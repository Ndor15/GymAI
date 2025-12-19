# 🚀 Guide Rapide Firebase - GymAI

## Méthode Simple (Recommandée)

### 1️⃣ Installer FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2️⃣ Configurer Firebase automatiquement
```bash
flutterfire configure
```
- Sélectionne ton projet Firebase (ou crée-en un nouveau)
- Choisis les plateformes : Android et iOS
- Cela va générer `lib/firebase_options.dart` automatiquement

### 3️⃣ Modifier lib/main.dart
Ajoute l'import en haut du fichier :
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

### 4️⃣ Activer les services dans Firebase Console
1. Va sur https://console.firebase.google.com
2. Sélectionne ton projet
3. **Authentication** :
   - Clic sur "Commencer"
   - Active "Email/Password"
4. **Firestore Database** :
   - Clic sur "Créer une base de données"
   - Choisis "Mode test" (pour commencer)
   - Région : europe-west1 (ou plus proche de toi)
5. **Storage** :
   - Clic sur "Commencer"
   - Choisis "Mode test"

### 5️⃣ Configurer les règles de sécurité

**Firestore Rules** (dans Firestore > Règles) :
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

**Storage Rules** (dans Storage > Règles) :
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

### 6️⃣ Lancer l'app
```bash
# Pour Android
flutter run

# Pour iOS
cd ios && pod install && cd ..
flutter run -d ios
```

---

## ⚠️ Points Importants

### ❌ Ne PAS tester sur Windows
Firebase a des problèmes de compatibilité avec Windows. Utilise :
- Un émulateur Android
- Un simulateur iOS
- Un vrai appareil mobile

### 🔐 Sécurité
Les règles "Mode test" permettent tout accès pendant 30 jours. Assure-toi de configurer les règles de sécurité comme indiqué ci-dessus.

### 📝 Première utilisation
1. L'app va d'abord afficher la page de **Login**
2. Clic sur "**Créer un compte**"
3. Entre :
   - Un username (unique)
   - Un email
   - Un mot de passe (6+ caractères)
4. Tu seras automatiquement connecté
5. Tu verras l'**onboarding**, puis le **feed**

---

## 🐛 Problèmes Courants

### "No Firebase App has been created"
→ Tu n'as pas lancé `flutterfire configure` ou les fichiers ne sont pas au bon endroit

### "PERMISSION_DENIED"
→ Vérifie les règles Firestore/Storage dans la console Firebase

### iOS ne compile pas
```bash
cd ios
pod install
pod update
cd ..
flutter clean
flutter pub get
flutter run -d ios
```

### Android ne compile pas
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Documentation Complète
Voir `FIREBASE_SETUP.md` pour plus de détails et la configuration manuelle.
