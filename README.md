# 📚 Stundenplan App

Eine moderne Flutter-App zur Verwaltung von Stundenplänen, Zeiterfassung und Terminen – mit lokaler Speicherung und optionaler Cloud-Synchronisierung.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-blue?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-lightgrey)
![License](https://img.shields.io/badge/License-Private-red)

---

## ✨ Features

### 📅 Stundenplan & Termine
- **Kalenderansicht** mit Tages-, Wochen- und Monatsübersicht
- **Termine erstellen, bearbeiten und löschen** mit Start-/Endzeit
- **Kategorisierung** mit anpassbaren Farben
- **Veranstaltungstypen** (Vorlesung, Übung, Seminar, etc.)
- **Ortsangaben** für jeden Termin
- **Wiederholende Termine** (in Vorbereitung)

### ⏱️ Zeittracker
- **Aktivitäten tracken** – für Veranstaltungen oder eigene Aktivitäten
- **Start, Pause, Stopp** mit Hintergrund-Tracking (Android)
- **Detaillierte Statistiken** nach Tag, Woche und Monat
- **Wochenziele** pro Kategorie mit Fortschrittsanzeige
- **Vordefinierte Aktivitäten** zur schnellen Auswahl

### 📊 Statistiken & Auswertungen
- **Dashboard** mit Gesamtübersicht
- **Auswertung nach Aktivität und Kategorie**
- **Fortschrittsbalken** und Prozentanzeigen
- **Historische Daten** über Wochen- und Monatsauswahl

### 🎨 Design & Bedienung
- **Material 3 Design** mit modernem Look
- **Dark Mode** (Hell, Dunkel, System)
- **Responsive Design** für alle Bildschirmgrößen
- **Intuitive Navigation** mit Bottom Navigation Bar

### 🔔 Benachrichtigungen (Android)
- **Push-Benachrichtigungen** vor Terminen
- **Foreground Service** für laufende Zeiterfassung
- **Notification Actions** zum Pausieren/Stoppen

### 💾 Datenverwaltung
- **Lokale SQLite-Datenbank** – funktioniert offline
- **Export/Import** als JSON-Backup
- **Optionale Cloud-Sync** über Supabase

---

## 🚀 Installation

### Voraussetzungen
- Flutter SDK 3.9.2 oder höher
- Android Studio / VS Code mit Flutter Extensions
- Für Windows: Visual Studio Build Tools

### Setup

```bash
# Repository klonen
git clone https://github.com/yourusername/stundenplan.git
cd stundenplan

# Dependencies installieren
flutter pub get

# App starten
flutter run -d android    # Für Android
flutter run -d windows    # Für Windows
```

### Release Build

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release
```

---

## 📱 Verwendung

### Termine verwalten
1. **Neuer Termin**: Tap auf den FAB (+) im Stundenplan-Tab
2. **Details eingeben**: Titel, Typ, Zeit, Ort und Kategorie
3. **Bearbeiten/Löschen**: Tap auf einen Termin in der Liste

### Zeit tracken
1. **Aktivität starten**: Tap auf "Aktivität starten" im Zeittracker-Tab
2. **Quelle wählen**: Vordefinierte Aktivität oder Veranstaltung
3. **Pausieren/Beenden**: Buttons in der laufenden Aktivitäts-Karte
4. **Statistiken ansehen**: Tap auf das Chart-Icon oben rechts

### Kategorien verwalten
1. **Einstellungen → Kategorien**
2. **Neue Kategorie**: Name, Farbe und optionales Wochenziel
3. **Wochenziele**: Werden in den Wochen-Statistiken angezeigt

---

## 🗂️ Projektstruktur

```
lib/
├── config/                 # Konfiguration (Supabase, etc.)
├── models/                 # Datenmodelle
│   ├── activity_track.dart     # Zeiterfassung
│   ├── category.dart           # Kategorien
│   ├── predefined_activity.dart
│   └── schedule_item.dart      # Termine
├── providers/              # State Management (Provider)
│   ├── activity_provider.dart
│   ├── schedule_provider.dart
│   └── theme_provider.dart
├── screens/                # UI Screens
│   ├── activity/               # Zeittracker
│   ├── categories/             # Kategorien-Verwaltung
│   ├── home/                   # Hauptbildschirm
│   ├── schedule/               # Stundenplan
│   ├── settings/               # Einstellungen
│   └── stats/                  # Statistiken
├── services/               # Backend Services
│   ├── local_database_service.dart
│   ├── foreground_service.dart
│   └── notification_service.dart
├── widgets/                # Wiederverwendbare Widgets
└── main.dart               # App Entry Point
```

---

## 🛠️ Technologien

| Technologie | Verwendung |
|-------------|------------|
| **Flutter** | Cross-Platform Framework |
| **Provider** | State Management |
| **SQLite (sqflite)** | Lokale Datenbank |
| **Table Calendar** | Kalender-Widget |
| **Flutter Foreground Task** | Hintergrund-Tracking (Android) |
| **Material 3** | Modernes UI Design |
| **Supabase** | Optionale Cloud-Sync |

---

## 📋 Roadmap

- [x] Grundlegende Stundenplan-Verwaltung
- [x] Kategorien mit Farbauswahl
- [x] Zeittracker mit Pause-Funktion
- [x] Statistiken nach Tag/Woche/Monat
- [x] Wochenziele pro Kategorie
- [x] Dark Mode
- [x] Export/Import Funktionalität
- [ ] Wiederkehrende Termine
- [ ] Widget für Android Homescreen
- [ ] iOS Support
- [ ] Teilen von Terminen

---

## 🐛 Troubleshooting

### Build-Fehler beheben
```bash
flutter clean
flutter pub get
flutter run
```

### Android Benachrichtigungen funktionieren nicht
- Überprüfen Sie die App-Berechtigungen in den Einstellungen
- Batterie-Optimierung für die App deaktivieren

### Windows Build schlägt fehl
- Visual Studio Build Tools installieren
- C++ Desktop Development Workload aktivieren

---

## 📄 Lizenz

Dieses Projekt ist für private Nutzung erstellt.

---

## 🤝 Beitragen

Bei Fragen, Bugs oder Feature-Requests erstellen Sie ein Issue im Repository.
