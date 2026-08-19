# Arvan Photos 📸

A professional Flutter application for cloud-synced photo management, specifically integrated with **ArvanCloud S3 Object Storage**. This project demonstrates a production-grade architecture with a focus on reliability, scalability, and clean code.

---

## 🌍 Language Versions

- [**Persian (فارسی)**](README_FA.md) - [Click to read the Persian documentation / برای خواندن داکیومنت فارسی کلیک کنید]

---

## 🚀 Features

- ☁️ **ArvanCloud S3 Integration**: Full lifecycle management of photos using S3 (List, Upload, Download, Delete).
- 🔄 **Smart Backup System**: Background synchronization service for seamless photo backups.
- 📱 **Local Gallery Access**: Efficient indexing and display of device photos using `photo_manager`.
- 💾 **Offline-First Approach**: Local metadata caching using **SQFlite** for smooth performance even without internet.
- 🖼️ **Image Processing**: On-device image cropping and picking before cloud upload.
- 🔔 **Real-time Notifications**: Background task progress updates via local notifications.
- 🎨 **Modern UI**: Clean, responsive interface with shimmer effects and cached network images.

---

## 💎 Technical Highlights

- **Custom S3 Implementation**: Instead of using heavy SDKs, a lightweight and efficient S3 client was implemented using `Dio` and `AWS Signature V4`. This allows for fine-grained control over network requests and smaller app size.
- **Background Sync Engine**: Implements a unified background service that monitors gallery changes and handles uploads resiliently, ensuring user data is always backed up without draining the battery.
- **Strict Linting**: Follows `very_good_analysis` for high-quality, consistent code standards.
- **Error Handling**: Comprehensive error handling strategy using functional programming patterns (Dartz `Either`) to manage network failures, permission issues, and server errors gracefully.

---

## 🏗️ Architecture

This project follows the **Clean Architecture** principles, ensuring a strict separation of concerns and high testability.

### Layers:
1. **Core**: Contains cross-cutting concerns like Dependency Injection, Network clients (S3 Signature V4), Theme, and global Errors/Exceptions.
2. **Domain**: The heart of the application containing **Entities**, **Use Cases**, and **Repository Interfaces**. It is independent of any external libraries.
3. **Data**: Implementation of repository interfaces, **Models** (for JSON/XML mapping), and **Data Sources** (Remote/Local).
4. **Presentation**: UI layer using the **BLOC (Business Logic Component)** pattern for state management.

### Design Patterns & Tools:
- **State Management**: `flutter_bloc` for predictable state transitions.
- **Dependency Injection**: `get_it` & `injectable` for robust decoupling.
- **Functional Programming**: `dartz` for handling failures/results (Either type).
- **Service Locator**: Centralized service management.
- **API Communication**: `Dio` with interceptors for S3 Signature V4 authentication.

---

## 🛠️ Tech Stack

| Category | Tools |
| :--- | :--- |
| **Framework** | Flutter, Dart |
| **State Management** | BLoC |
| **Networking** | Dio, AWS Signature V4 |
| **Local Database** | SQFlite |
| **Dependency Injection** | GetIt, Injectable |
| **Image Handling** | Image Picker, Image Cropper, Photo Manager |
| **Background Tasks** | Flutter Background Service |
| **Testing** | Bloc Test, Mocktail |

---

## ⚙️ Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone [repository-url]
   ```

2. **Environment Variables**:
   Create an `.env` file in `assets/` with your ArvanCloud credentials:
   ```env
   S3_ACCESS_KEY=your_access_key
   S3_SECRET_KEY=your_secret_key
   S3_ENDPOINT=your_endpoint
   S3_BUCKET_NAME=your_bucket_name
   S3_REGION=your_region
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run Build Runner**:
   Generate DI and Model code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the App**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

The project includes unit and bloc tests to ensure reliability.
```bash
flutter test
```
