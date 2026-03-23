# 🔄 App neu starten ohne Löschen

## Problem
- Weißer Bildschirm in `ProgramManagementView` ❌
- App muss neu gestartet werden
- **ABER:** Möchtest Daten behalten

## 🔧 Fixes

### 1. Weißer Bildschirm Fix

**Problem:** `@Environment(\.dismiss)` fehlte

```swift
// Vorher:
struct ProgramManagementView: View {
    @Environment(\.modelContext) private var context
    // ❌ dismiss fehlt!
}

// Nachher:
struct ProgramManagementView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss  // ✅
}
```

**Außerdem:** "Fertig" Button fehlte in Toolbar

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button("Fertig") {
            dismiss()  // ✅
        }
    }
}
```

## 🔄 App neu starten - 3 Methoden

### Methode 1: **Hot Reload** ⚡ (Empfohlen!)

Seit iOS 18 / Xcode 16:

```
1. Ändere beliebigen Code
   (z.B. füge Leerzeile hinzu)

2. Cmd + R (oder Play-Button)

3. Xcode fragt:
   "Replace running instance on iPhone?"
   
4. Wähle: "Replace"

5. ✅ App startet neu
   ✅ Daten bleiben erhalten!
```

**Vorteile:**
- ✅ Schnell (< 5 Sekunden)
- ✅ Daten bleiben
- ✅ Kein manuelles Löschen

### Methode 2: **In-App Reset** 🔄

Nutze den neuen "App zurücksetzen" Button:

```
1. Öffne App
2. Mehr-Tab → Einstellungen
3. Scroll zu "Entwickler"
4. "App zurücksetzen (Onboarding)"
5. Tap!
6. ✅ Beim nächsten Start: Onboarding
7. ✅ Daten bleiben erhalten!
```

**Code:**
```swift
// In SettingsView.swift
Section {
    Button {
        resetToOnboarding()
    } label: {
        Label("App zurücksetzen (Onboarding)", systemImage: "arrow.counterclockwise")
    }
} header: {
    Text("Entwickler")
} footer: {
    Text("Setzt die App zurück und zeigt das Onboarding erneut. Daten bleiben erhalten.")
}

func resetToOnboarding() {
    UserDefaults.standard.set(false, forKey: "onboardingDone")
}
```

### Methode 3: **Simulator Reset** 🖥️

Nur für Simulator (nicht iPhone):

```
1. In Xcode: Device Menu
2. "Erase All Content and Settings..."
3. ❌ Löscht ALLES (Daten + App)
```

**Nachteile:**
- ❌ Löscht alle Daten
- ❌ Nur für Simulator

### Methode 4: **UserDefaults manuell löschen**

In Xcode Console:

```swift
// In AppDelegate oder irgendwo während Entwicklung:
#if DEBUG
UserDefaults.standard.dictionaryRepresentation().keys.forEach {
    UserDefaults.standard.removeObject(forKey: $0)
}
#endif
```

## 🎯 Empfehlung für Entwicklung

### Während Entwicklung:

**1. Hot Reload (Methode 1)** ⚡
- Für schnelle Code-Änderungen
- Cmd + R → Replace

**2. In-App Reset (Methode 2)** 🔄
- Für Onboarding-Tests
- Settings → "App zurücksetzen"

**3. Daten löschen (wenn nötig)** 🗑️
- Settings → "Alle Trainingsdaten löschen"
- Nur wenn Datenbank-Probleme

### Für Testing:

```
Szenario: UI-Änderung testen
→ Hot Reload (Cmd + R)

Szenario: Onboarding testen
→ In-App Reset Button

Szenario: Frische Installation simulieren
→ App löschen + neu installieren
```

## 🆕 Was hinzugefügt wurde:

### 1. `ProgramManagementView.swift`
```swift
// NEU: dismiss Environment
@Environment(\.dismiss) private var dismiss

// NEU: Fertig Button
ToolbarItem(placement: .topBarLeading) {
    Button("Fertig") { dismiss() }
}
```

### 2. `SettingsView.swift`
```swift
// NEU: Entwickler-Section
Section {
    Button {
        resetToOnboarding()
    } label: {
        Label("App zurücksetzen (Onboarding)", systemImage: "arrow.counterclockwise")
    }
} header: {
    Text("Entwickler")
}

// NEU: Reset-Funktion
func resetToOnboarding() {
    UserDefaults.standard.set(false, forKey: "onboardingDone")
}
```

## 📱 UI-Flow

### Settings mit Reset-Button:

```
┌─────────────────────────────────────┐
│ Einstellungen                       │
├─────────────────────────────────────┤
│ Benachrichtigungen                  │
│ Training-Erinnerung: ✓              │
│                                     │
│ Zyklus-Einstellungen                │
│ Zykluslänge: 28 Tage                │
│                                     │
│ Über FemFit                         │
│ Version: 1.0.0                      │
│                                     │
│ Daten                               │
│ 🗑️ Alle Trainingsdaten löschen      │
│                                     │
│ Entwickler (NEU!)                   │
│ 🔄 App zurücksetzen (Onboarding)    │
└─────────────────────────────────────┘
```

## ⚡ Quick Reference

### Problem → Lösung:

```
Problem: Weißer Bildschirm
→ Lösung: dismiss Environment hinzufügen ✅

Problem: Code-Änderung testen
→ Lösung: Cmd + R → Replace ✅

Problem: Onboarding neu starten
→ Lösung: Settings → Reset Button ✅

Problem: Daten löschen
→ Lösung: Settings → Trainingsdaten löschen ✅

Problem: Komplett-Reset
→ Lösung: App löschen + neu installieren
```

## 🔍 Debug-Tipps

### 1. **Console prüfen**
```
Cmd + Shift + Y (Console einblenden)
Suche nach Errors oder Warnings
```

### 2. **Breakpoints setzen**
```
Klick auf Zeilen-Nummer
→ Blauer Punkt erscheint
→ App pausiert hier
```

### 3. **Print-Debugging**
```swift
func someFunction() {
    print("🔍 someFunction aufgerufen")
    print("📊 Wert: \(someValue)")
}
```

### 4. **SwiftData Viewer**
```
Xcode → View → Inspectors → Show SwiftData Inspector
→ Zeigt alle gespeicherten Daten
```

## 🎓 Best Practices

### Während Entwicklung:

```swift
// 1. Debug-Flag nutzen
#if DEBUG
    // Nur in Debug-Build
    Button("Reset Data") { resetData() }
#endif

// 2. Print-Statements
print("✅ Speichern erfolgreich")
print("❌ Fehler: \(error)")

// 3. Assertions
assert(programs.count > 0, "Sollte Programme haben")
```

### Für Production:

```swift
// Entwickler-Optionen verstecken
#if !DEBUG
    // Kein Reset-Button in Production
#endif
```

---

**Stand:** 23. März 2026  
**Version:** 2.1 - Hot Reload + In-App Reset
