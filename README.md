<p align="center">
  <img src="assets/images/app_icon.png" alt="Smart Fridge Logo" width="120" />
</p>

<h1 align="center">🧊 Smart Fridge — AI-Powered Ingredient, Receipt & Recipe Manager</h1>

<p align="center">
  <em>Smart Fridge is an AI-powered mobile application that helps users manage food ingredients, scan supermarket receipts, and discover personalized recipes effortlessly.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Gemini_AI-Powered-8E75B2?logo=google" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/Computer_Vision-ML_Kit-4285F4?logo=google" alt="Computer Vision" />
  <img src="https://img.shields.io/badge/Architecture-Clean_Architecture-green" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/State_Management-BLoC-blue" alt="BLoC" />
</p>

---

## 📖 About

Smart Fridge is an AI-powered mobile application that helps users organize groceries, reduce food waste, and simplify meal planning.

Using **Google ML Kit**, the application detects ingredients directly from photos and stores them inside a **virtual refrigerator**.

In addition, users can upload **supermarket receipts**, where AI automatically extracts purchased food items and adds them to the virtual fridge without manual typing, making inventory management faster and more convenient.

Powered by **Google Gemini AI**, Smart Fridge analyzes the ingredients currently available and generates personalized recipe recommendations tailored to what users already have. Whether ingredients are added manually, detected from images, or extracted from shopping receipts, the app provides a smarter and more efficient cooking experience.

---

## 🎬 Demo Video

https://github.com/user-attachments/assets/7bb8679d-0127-4b04-b605-b6ffee916355

---

## 📸 Screenshots

### Light Mode & Dark Mode

| Screen | Light Mode | Dark Mode |
|:------:|:----------:|:---------:|
| **Home** | <img src="assets/screen_shots/home_light.png" width="250"/> | <img src="assets/screen_shots/home_view_dark.png" width="250"/> |
| **Search** | <img src="assets/screen_shots/search_view_light.png" width="250"/> | <img src="assets/screen_shots/search_view_dark.png" width="250"/> |
| **Recipe Info** | <img src="assets/screen_shots/recipe_info_light.png" width="250"/> | <img src="assets/screen_shots/recipe_info_dark.png" width="250"/> |
| **My Items (Virtual Fridge)** | <img src="assets/screen_shots/my_item_light.png" width="250"/> | <img src="assets/screen_shots/my_item_dark.png" width="250"/> |
| **Saved Recipes** | <img src="assets/screen_shots/saved_view_light.png" width="250"/> | <img src="assets/screen_shots/saved_view_dark.png" width="250"/> |
| **Profile** | <img src="assets/screen_shots/profile_light.png" width="250"/> | <img src="assets/screen_shots/profile_dark.png" width="250"/> |
| **Voice Search** | <img src="assets/screen_shots/voice_search_light.png" width="250"/> | <img src="assets/screen_shots/voice_search_dark.png" width="250"/> |

### Other Screens

| Screen | Preview |
|:------:|:-------:|
| **Scan Ingredients** | <img src="assets/screen_shots/scan_photo_light.png" width="250"/> |
| **Receipt Scanner** | <img src="assets/screen_shots/receipt_scan_light.png" width="250"/> |
| **Loading** | <img src="assets/screen_shots/loading_dark.png" width="250"/> |

---

## ✨ Key Features

- 📷 **Ingredient Recognition** — Detect ingredients from photos using Google ML Kit
- 🧾 **Receipt Scanner** — Upload supermarket receipts and automatically extract purchased ingredients into your virtual fridge
- 🧊 **Virtual Refrigerator** — Store and organize all available ingredients in one place
- 🤖 **AI Recipe Generator** — Google Gemini AI creates personalized recipes based on your available ingredients
- 📊 **Smart Inventory Management** — Automatically keep your fridge inventory up to date
- 🔍 **Smart Search** — Search meals by ingredient, category, cuisine, or meal name
- 🎤 **Voice Search** — Find recipes using speech-to-text
- 💾 **Save Recipes** — Bookmark favorite recipes for quick access
- 🏥 **Health Profile** — Personalize recommendations based on dietary preferences and health conditions
- 🌗 **Dark & Light Mode** — Full theme support
- ⚡ **Offline Support** — Hive local storage for fridge items and saved recipes
- 🎨 **Smooth User Experience** — Beautiful animations, shimmer loading, and modern UI

---

## 🏗️ Architecture

Smart Fridge follows **Clean Architecture** principles with a feature-first folder structure and uses the **BLoC / Cubit** pattern for state management.

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│       (Pages, Widgets, BLoCs/Cubits)         │
├─────────────────────────────────────────────┤
│                Domain Layer                  │
│       (Entities, Use Cases, Repos)           │
├─────────────────────────────────────────────┤
│                 Data Layer                   │
│  (Models, DataSources, Repo Implementations) │
└─────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Category | Technology |
|:---------|:-----------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.5+ |
| **State Management** | flutter_bloc / Cubit |
| **Dependency Injection** | GetIt |
| **Networking** | Dio |
| **Local Storage** | Hive |
| **Navigation** | GoRouter |
| **AI** | Google Gemini AI |
| **Computer Vision** | Google ML Kit |
| **OCR / Receipt Processing** | Google ML Kit Text Recognition |
| **Speech Recognition** | speech_to_text |
| **Camera** | camera, image_picker |
| **Animations** | Lottie, flutter_animate, shimmer |
| **Environment Config** | flutter_dotenv |
| **Fonts** | Google Fonts |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.5.0`
- Dart SDK `>=3.5.0`
- Android Studio / VS Code
- A valid Gemini API Key

### Installation

1. Clone the repository

```bash
git clone https://github.com/your-username/smart-fridge.git
cd smart-fridge
```

2. Create a `.env` file

```env
GEMINI_API_KEY=your_api_key_here
```

3. Install dependencies

```bash
flutter pub get
```

4. Run the application

```bash
flutter run
```

---

## 📡 APIs & AI Technologies

| Technology | Purpose |
|:-----------|:--------|
| Google Gemini AI | Generate personalized recipes |
| Google ML Kit Image Labeling | Detect ingredients from images |
| Google ML Kit Text Recognition | Extract food items from supermarket receipts |
| TheMealDB API | Recipes, meal details, categories, and ingredient images |

---

## 📄 License

This project is intended for educational and personal use.

---

<p align="center">
  Made with ❤️ using Flutter & AI
</p>
