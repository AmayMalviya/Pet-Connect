# Pet-Connect
## 📌 Project Overview
The **Pet-Connect App** is a Flutter-based mobile application designed to help pet owners manage their pets' health, locate pet-friendly services, facilitate adoption, and build a pet-loving community. The app integrates **Firebase** for authentication, database, and storage, ensuring a seamless experience for users.

## 🎯 Features
### 1️⃣ **Simplify Pet Care**
- Maintain pet medical records
- Track vaccinations & health history
- Set reminders for vet visits

### 2️⃣ **Enhance Community Engagement**
- Connect with other pet owners
- Join forums & discussions
- Schedule & attend pet meetups

### 3️⃣ **Improve Pet Adoption**
- Connect adopters with shelters & rescues
- View pet adoption listings
- Contact shelters directly

### 4️⃣ **Promote Pet-Friendly Services**
- Find nearby vets, trainers, parks, and pet stores
- Access ratings & reviews

### 5️⃣ **Provide Pet Products**
- Buy pet food, accessories, and essentials
- Browse products from verified sellers

## 🛠️ Tech Stack
- **Flutter** (UI Development)
- **Firebase** (Authentication, Firestore Database, Storage, Messaging) and Java SPRING BOOT.
- **Google Maps API** (Pet service locator)
- **Cloud Functions** (Business logic & automation)
- **VS Code** (Development Environment)

## 📲 Installation & Setup
### 1️⃣ Prerequisites
- Install [Flutter](https://flutter.dev/docs/get-started/install)
- Install [VS Code](https://code.visualstudio.com/)
- Install Flutter & Dart extensions in VS Code
- Install [Firebase CLI](https://firebase.google.com/docs/cli) (for Firebase setup)
- Create a Firebase project ([Firebase Console](https://console.firebase.google.com/))

### 2️⃣ Clone the Repository
```bash
  git clone https://github.com/AmayMalviya/Pet-Connect.git
  cd Pet-Connect
```

### 3️⃣ Install Dependencies
```bash
  flutter pub get
```

### 4️⃣ Configure Firebase
- Install Firebase CLI:  
  ```bash
  npm install -g firebase-tools
  ```
- Login to Firebase:  
  ```bash
  firebase login
  ```
- Initialize Firebase:  
  ```bash
  firebase init
  ```
- Add `google-services.json` (Android) inside `android/app/`
- Add `GoogleService-Info.plist` (iOS) inside `ios/Runner/`
- Enable Firestore, Authentication, and Storage in Firebase

### 5️⃣ Run the App in VS Code
- Open VS Code and navigate to the project folder
- Open a new terminal and run:
  ```bash
  flutter run
  ```

## 📂 Folder Structure
```
lib/
│── main.dart                # App Entry Point
│── screens/                 # UI Screens
│── widgets/                 # Reusable UI Components
│── services/                # Firebase & API Services
│── models/                  # Data Models
│── utils/                   # Helper Functions
```

## 🚀 Roadmap
- [x] Firebase Authentication (Email, Google Login)
- [x] MySql Database (Relational Data Storage)
- [ ] Pet Service Locator (Google Maps API)
- [ ] Pet Adoption Module
- [ ] E-commerce Integration for Pet Products
- [ ] Push Notifications & Reminders

## 📜 License
This project is licensed under the **MIT License**.

## 🤝 Contributing
Pull requests are welcome! Please open an issue first to discuss any changes.

## 📬 Contact
- **Email**: amaymalviya2@gmail.com
- **GitHub**: (https://github.com/AmayMalviya)
- **LinkedIn**: (www.linkedin.com/in/amay-malviya-837061256)
