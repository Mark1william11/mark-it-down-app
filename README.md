# Mark It Down 📝

**Your personal task champion with offline-first cloud synchronization.**

Mark It Down is a beautiful, feature-rich, and modern To-Do application built with Flutter. It's designed not just to track tasks, but to provide a delightful and productive user experience, from its animated UI to its powerful "Focus Mode". This project showcases a full-stack mobile application built on a clean, scalable architecture.

---

## 📸 Screenshots & Demo

| Light Mode                                                                                                                              | Dark Mode                                                                                                                               |
| :--------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------: |
| ![Light Mode Screenshot 1](https://github.com/user-attachments/assets/ec820b87-894f-4ae6-936f-35faaeb1057a)                                | ![Dark Mode Screenshot 1](https://github.com/user-attachments/assets/7b3c73cd-4db3-41d1-917a-cd38fe99db01)                                 |
| *Login Screen*                                                                                                                           | *Home Screen (Dark)*                                                                                                                     |
| ![Light Mode Screenshot 2](https://github.com/user-attachments/assets/7a2f7210-b843-43b7-903f-ba4647391028)                                | ![Dark Mode Screenshot 2](https://github.com/user-attachments/assets/cc36fd19-27a1-4d89-bf1b-052bae9ec652)                                 |
| *Stats Screen*                                                                                                                           | *Focus Mode*                                                                                                                             |

**Video Demo:**

*Replace this line with your embedded GIF or a link to a video!*

---

## ✨ Features

*   **Full User Authentication:** Secure sign-up and login using Firebase Authentication.
*   **Offline-First Cloud Sync:** Tasks are instantly saved to a local database for offline access and then seamlessly synchronized to Firestore in the background. Your data is always available and safe.
*   **Complete Task Management (CRUD):** Create, read, update, and delete tasks with an intuitive UI.
*   **Advanced Task Properties:** Add due dates, priorities (High, Medium, Low), and custom focus durations to each task.
*   **Sub-tasks:** Break down large tasks into smaller, manageable steps with individual completion status.
*   **Interactive Focus Mode:** A dedicated screen with a countdown timer and motivational quotes to help you concentrate on a single task.
*   **Animated Statistics Dashboard:** A beautiful, animated stats screen with charts to visualize your productivity, including completions by priority and weekly trends.
*   **Dynamic UI:**
    *   **Light & Dark Modes:** A beautiful, custom theme that adapts to system settings.
    *   **Sorting & Filtering:** Sort tasks by creation date, due date, or priority. Filter by active or completed status.
    *   **Real-time Search:** Instantly find tasks with a debounced search implementation.
*   **Polished User Experience:**
    *   Subtle animations throughout the app using `flutter_animate`.
    *   Haptic feedback for key interactions.
    *   A celebratory confetti effect for completing all tasks.
    *   Glassmorphism `AppBar` for a modern, layered look.
    *   Custom-designed widgets for a unique, branded feel.

---

## 🛠️ Tech Stack & Architecture

This project was built with a modern, scalable, and professional tech stack.

### Core Technologies
*   **Framework:** Flutter
*   **State Management:** Riverpod (with code generation)
*   **Backend:** Firebase (Authentication & Firestore Database)
*   **Local Database:** Drift (SQLite) for offline-first persistence.
*   **Routing:** GoRouter
*   **UI Packages:** `flutter_animate`, `fl_chart`, `google_fonts`, `flutter_hooks`

### Architecture
The app follows a clean, layered architecture to ensure separation of concerns and maintainability.

*   **`Data` Layer:** Handles all data operations.
    *   **Models:** Plain Dart objects representing the app's data structures (`Todo`, `SubTask`).
    *   **Repository:** The single source of truth for data. It abstracts the data sources and implements the offline-first sync logic between the local database and Firestore.
    *   **Datasource:** The concrete implementation of the local database using Drift.
*   **`Logic` Layer:** Contains the core business logic, decoupled from the UI.
    *   **Services:** Classes like `AuthService`, `TodoService`, and `NotificationService` that orchestrate data operations and implement business rules.
*   **`Presentation` Layer:** The UI of the application.
    *   **Screens:** The main pages of the app (`HomeScreen`, `AuthScreen`, etc.).
    *   **Notifiers/Providers:** Riverpod providers that manage the state of the UI and connect it to the logic layer.
    *   **Widgets:** Reusable UI components that make up the screens.
*   **`Routing` Layer:** Defines all navigation paths and rules using GoRouter, including authentication-based redirects.

---

## 🚀 Setup & Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/your-username/mark-it-down-app.git
   ```
2. Navigate to the project directory:
   ```sh
   cd mark-it-down-app
   ```
3. Set up a Firebase project and connect it to the app by running `flutterfire configure`. Remember to add your SHA-1/SHA-256 fingerprints and enable the Email/Password sign-in provider.
4. Get dependencies:
   ```sh
   flutter pub get
   ```
5. Run the build runner:
   ```sh
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
