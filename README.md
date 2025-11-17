# Stundenplan App

Eine flexible Flutter-App zur Verwaltung von Stundenplänen und Terminen mit Supabase-Synchronisierung zwischen Windows und Android.

## Features

✨ **Kernfunktionen:**
- 📅 Kalenderansicht mit Tages- und Wochenansicht
- ➕ Termine erstellen, bearbeiten und löschen
- 🏷️ Kategorisierung von Terminen mit Farben
- 📍 Ortsangaben für Termine
- 🔄 Wiederholende Termine (in Vorbereitung)
- 💾 Automatische Synchronisierung über Supabase
- 🌓 Dark Mode Support
- 📱 Responsive Design für Windows und Android

## Installation

### Voraussetzungen
- Flutter SDK (Version 3.9.2 oder höher)
- Supabase Account

### Setup

1. **Dependencies installieren:**
```bash
flutter pub get
```

2. **Für Windows:**
```bash
flutter run -d windows
```

3. **Für Android:**
```bash
flutter run -d android
```

## Supabase Konfiguration

Die Supabase-Konfiguration befindet sich in `lib/config/supabase_config.dart`.

Die Datenbank wurde bereits mit folgendem Schema erstellt:
- `profiles` - Benutzerprofile
- `categories` - Kategorien für Termine
- `schedule_items` - Termine/Events
- `notifications` - Benachrichtigungen

## Verwendung

### 1. Registrierung / Anmeldung
- Beim ersten Start registrieren Sie sich mit E-Mail und Passwort
- Bei der Anmeldung werden Ihre Daten automatisch synchronisiert

### 2. Termine erstellen
- Tippen Sie auf den "Neuer Termin" Button
- Füllen Sie Titel, Beschreibung und Ort aus
- Wählen Sie Start- und Endzeit
- Wählen Sie eine Farbe zur Visualisierung
- Speichern Sie den Termin

### 3. Termine ansehen
- Die Kalenderansicht zeigt alle Termine
- Wechseln Sie zwischen Wochen- und Monatsansicht
- Tippen Sie auf einen Tag, um alle Termine für diesen Tag zu sehen
- Tippen Sie auf einen Termin, um Details zu sehen oder ihn zu bearbeiten

### 4. Termine bearbeiten/löschen
- Tippen Sie auf einen Termin in der Liste
- Bearbeiten Sie die Details und speichern Sie
- Oder löschen Sie den Termin mit dem Papierkorb-Icon

## Projektstruktur

```
lib/
├── config/              # Konfigurationsdateien (Supabase)
├── models/              # Datenmodelle
├── providers/           # State Management (Provider)
├── screens/             # UI Screens
│   ├── auth/           # Login/Registrierung
│   ├── home/           # Hauptbildschirm
│   └── schedule/       # Termin-Verwaltung
├── services/           # Backend Services (Supabase)
├── widgets/            # Wiederverwendbare Widgets
└── main.dart           # App Entry Point
```

## Neu hinzugefügte Features

✅ **Erweiterte Funktionen:**
- 🔔 **Push-Benachrichtigungen für Android** - Erhalten Sie Benachrichtigungen 15 Minuten vor Ihren Terminen
- 🏷️ **Kategorien-Verwaltung** - Vollständige CRUD-Funktionalität für Kategorien mit Farbauswahl
- 🔍 **Such- und Filterfunktion** - Durchsuchen Sie Termine nach Titel, Beschreibung, Ort oder Kategorie
- 📊 **Statistik-Dashboard** - Detaillierte Statistiken über Ihre Termine (Anzahl, Dauer, Kategorieverteilung, aktivste Tage)
- 🌙 **Theme-Verwaltung** - Wechseln Sie zwischen hellem, dunklem und System-Theme
- 📅 **Wochenübersicht** - Separate Wochenansicht mit kompaktem Layout für alle 7 Tage

## Mögliche Erweiterungen

- [ ] Wiederkehrende Termine vollständig implementieren
- [ ] Export/Import Funktionalität
- [ ] Teilen von Terminen
- [ ] Offline-Modus
- [ ] Widgets für Android Homescreen

## Technologien

- **Flutter** - Cross-Platform Framework
- **Supabase** - Backend as a Service
  - PostgreSQL Datenbank
  - Authentication
  - Realtime Synchronisierung
  - Row Level Security (RLS)
- **Provider** - State Management
- **Table Calendar** - Kalender-Widget
- **Material 3** - Modernes Design

## Troubleshooting

### Fehler beim Build
```bash
flutter clean
flutter pub get
flutter run
```

### Supabase Verbindungsprobleme
- Überprüfen Sie Ihre Internetverbindung
- Stellen Sie sicher, dass die Supabase URL und API Keys korrekt sind

### Windows Build Fehler
- Stellen Sie sicher, dass Visual Studio Build Tools installiert sind

## Lizenz

Dieses Projekt ist für private Nutzung erstellt.

## Support

Bei Fragen oder Problemen erstellen Sie ein Issue im Repository.
