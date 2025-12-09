# 🎓 UniTrack

**Schedule & Time Tracking for Students**

Eine Android-App zur Verwaltung von Stundenplänen und Zeiterfassung – komplett lokal, keine Cloud, keine Kosten.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-blue?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)
![License](https://img.shields.io/badge/License-MIT-brightgreen)

---

## 💡 Warum diese App?

Ich habe diese App entwickelt, um meinen eigenen Bedarf nach einer guten Stundenplan- und Zeiterfassungs-App zu decken – **ohne Geld für Pro-Versionen oder Abonnements auszugeben**.

Alle verfügbaren Apps waren entweder:
- Vollgestopft mit Werbung
- Nur mit kostenpflichtiger Pro-Version nutzbar
- Zu kompliziert oder nicht auf meine Bedürfnisse zugeschnitten

Also habe ich mir selbst eine gebaut. 🚀

---

## ✨ Features

### 📅 Stundenplan
- Kalenderansicht mit Tages-, Wochen- und Monatsübersicht
- Termine mit Start-/Endzeit, Ort und Kategorie
- Veranstaltungstypen (Vorlesung, Übung, Seminar, etc.)
- Farbige Kategorisierung

### ⏱️ Zeittracker
- Aktivitäten tracken – für Veranstaltungen oder eigene Aktivitäten
- Start, Pause, Stopp mit Hintergrund-Tracking
- Benachrichtigung mit Quick-Actions (Pause/Stop)
- Vordefinierte Aktivitäten zur schnellen Auswahl

### 📊 Statistiken
- Auswertung nach Tag, Woche und Monat
- Aufschlüsselung nach Aktivität und Kategorie
- Wochenziele pro Kategorie mit Fortschrittsanzeige

### 🎨 Design
- Material 3 Design
- Dark Mode (Hell, Dunkel, System)
- Intuitive Navigation

### 💾 Daten
- **100% lokal** – keine Cloud, keine Registrierung
- Export/Import als JSON-Backup
- SQLite-Datenbank

---

## 🚀 Installation

### Voraussetzungen
- Flutter SDK 3.9.2+
- Android Studio oder VS Code
- Android SDK

### Bauen & Installieren

```bash
# Repository klonen
git clone https://github.com/mehmetaras2206/unitrack.git
cd unitrack

# Dependencies installieren
flutter pub get

# Auf Android-Gerät installieren (USB-Debugging aktivieren)
flutter run

# Oder APK bauen
flutter build apk --release
```

Die APK findest du dann unter: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Verwendung

### Stundenplan
1. **+** Button → Neuen Termin erstellen
2. Titel, Typ, Zeit, Ort und Kategorie eingeben
3. Tap auf Termin zum Bearbeiten/Löschen

### Zeittracker
1. "Aktivität starten" → Aktivität oder Veranstaltung wählen
2. Buttons zum Pausieren/Beenden
3. Chart-Icon → Statistiken ansehen

### Kategorien
1. Einstellungen → Kategorien
2. Farbe und optionales Wochenziel setzen

---

## 🗂️ Projektstruktur

```
lib/
├── models/          # Datenmodelle
├── providers/       # State Management (Provider)
├── screens/         # UI Screens
├── services/        # Database & Background Services
└── widgets/         # Wiederverwendbare Widgets
```

---

## 🛠️ Technologien

| Technologie | Verwendung |
|-------------|------------|
| Flutter | Cross-Platform Framework |
| Provider | State Management |
| SQLite | Lokale Datenbank |
| Table Calendar | Kalender-Widget |
| Flutter Foreground Task | Hintergrund-Tracking |
| Material 3 | UI Design |

---

## 📋 Roadmap

- [x] Stundenplan-Verwaltung
- [x] Kategorien mit Wochenzielen
- [x] Zeittracker mit Pause
- [x] Statistiken
- [x] Dark Mode
- [x] Export/Import
- [ ] Wiederkehrende Termine
- [ ] Home-Screen Widget

---

## 🐛 Troubleshooting

```bash
# Bei Build-Fehlern
flutter clean
flutter pub get
flutter run
```

**Benachrichtigungen funktionieren nicht?**
- App-Berechtigungen prüfen
- Batterie-Optimierung deaktivieren

---

## 📄 Lizenz

MIT License – Frei verwendbar und modifizierbar.

---

## 🤝 Beitragen

Pull Requests sind willkommen! Bei Bugs oder Feature-Wünschen einfach ein Issue erstellen.
