# Nompangs Front

This Flutter application powers the Nompangs experience. It relies on Firebase for authentication and Firestore storage and uses a small Node.js backend located in `server/` for QR profile management.

## Prerequisites

- Flutter 3.x installed and added to your `PATH`
- Node.js 18 or later
- Firebase CLI (`npm install -g firebase-tools`)

## Getting Started

1. **Install Flutter**

   Follow the instructions on [flutter.dev](https://flutter.dev/docs/get-started/install). After installation run:
   ```bash
   flutter doctor
   ```
   to verify your environment.

2. **Fetch dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a Firebase project and log in with `firebase login`.
   - Configure the platforms with:
     ```bash
     flutterfire configure
     ```
   - Create a `.env` file in the project root containing your Firebase keys and any other environment variables required by the app.

4. **Set up the QR backend**

   The backend that stores QR profiles lives in the `server/` directory.
   To run it locally:
   ```bash
   cd server
   npm install
   npm start
   ```
   To deploy it as a Cloud Function:
   ```bash
   firebase deploy --only functions
   ```

## Development

- Start the application on a device or emulator:
  ```bash
  flutter run
  ```

- Run unit tests:
  ```bash
  flutter test
  ```

- Analyze the codebase:
  ```bash
  flutter analyze
  ```
