# 🗂️ Programm-Verwaltung & Template-System

## Übersicht

Das neue Verwaltungssystem ermöglicht es, Trainingsprogramme zentral zu verwalten, zu bearbeiten und zu löschen. Der **Plan-Generator wurde entfernt** zugunsten des **flexibleren Template-Systems**.

## 🎯 Entscheidung: Templates statt Plan-Generator

### Warum Templates?

✅ **Flexibler**
- Sofort einsatzbereit
- Professionell erstellt
- Anpassbar nach dem Erstellen

✅ **Einfacher**
- Keine komplizierte Setup-Prozedur
- Weniger Schritte bis zum ersten Training
- Klare Auswahl

✅ **Wartbarer**
- Einfacher neue Templates hinzuzufügen
- Weniger Code zu pflegen
- Bessere Performance

### Plan-Generator Nachteile:
- ❌ Zu viele Schritte
- ❌ Komplexe Logik
- ❌ Schwer zu testen
- ❌ Für Anfänger verwirrend

## 🆕 Neue Features

### 1. **Programm-Verwaltung** 📁

Zentrale Verwaltung für alle Programme mit:

```
┌─────────────────────────────────────┐
│ Programme verwalten                 │
├─────────────────────────────────────┤
│ 📊 3 Programme                      │
│ 📅 9 Trainingstage                  │
│ 💪 47 Übungen                       │
├─────────────────────────────────────┤
│ Meine Programme:                    │
│                                     │
│ 📂 Push Pull Legs                   │
│    3 Tage • 12 Sessions             │
│    ↓ Details anzeigen               │
│    • Push (5 Übungen)               │
│    • Pull (6 Übungen)               │
│    • Legs (4 Übungen)               │
│    [Bearbeiten] [Löschen]           │
│                                     │
│ 📂 Ganzkörper                       │
│    2 Tage • 5 Sessions              │
└─────────────────────────────────────┘
```

#### Features:
- ✅ **Alle Programme auf einen Blick**
- ✅ **Expandable Cards** für Details
- ✅ **Direkt zu Trainingstagen** navigieren
- ✅ **Löschen mit Bestätigung**
- ✅ **Stats-Übersicht** (Programme, Tage, Übungen)

### 2. **Template-System verbessert** ✨

Templates bleiben die **Hauptmethode** zum Erstellen von Programmen:

```
Home-Tab (Leerer Zustand):
┌─────────────────────────────────────┐
│ Noch kein Programm                  │
│                                     │
│ [Template nutzen] ← EMPFOHLEN       │
│ [Eigenes Programm]                  │
└─────────────────────────────────────┘
```

#### Verfügbare Templates:
1. **Push/Pull/Legs** (3-6x/Woche, Fortgeschritten)
2. **Ganzkörper** (2-3x/Woche, Anfänger)
3. **Oberkörper/Unterkörper** (4x/Woche, Mittel)
4. **Bro Split** (5-6x/Woche, Fortgeschritten)

### 3. **Übungen-Verwaltung** 🔧

Im `WorkoutDayView` kannst du jetzt:

- ✅ **Übungen bearbeiten** (Swipe links)
- ✅ **Übungen löschen** (Swipe rechts)
- ✅ **Übungen hinzufügen** (+ Button)
- ✅ **Reihenfolge ändern** (in Zukunft)

### 4. **Trainingstage-Verwaltung** 📅

Im `ManageWorkoutDaysView` kannst du:

- ✅ **Trainingstage umbenennen**
- ✅ **Trainingstage löschen**
- ✅ **Neue Tage hinzufügen**
- ✅ **Zu Trainingstag navigieren**

## 📱 Neue Navigation

### Zugriff auf Programm-Verwaltung:

#### Option 1: Profil-Tab
```
Profil → Programme verwalten
```

#### Option 2: Home-Tab
```
Home → + Button → Template nutzen / Eigenes Programm
```

#### Option 3: Trainingstage-Tab
```
Trainingstage → Verwalten
```

## 🗑️ Löschen-Funktionen

### Programme löschen:

```swift
// In ProgramManagementView
Button(role: .destructive) {
    showDeleteConfirmation = true
} label: {
    Label("Löschen", systemImage: "trash")
}

.alert("Programm löschen?") {
    Button("Löschen", role: .destructive) {
        deleteProgram(program)
    }
} message: {
    Text("Alle Trainingstage, Übungen und Sessions gehen verloren.")
}
```

#### Cascade Delete:
- ✅ Löscht **alle Trainingstage**
- ✅ Löscht **alle Übungen**
- ✅ Löscht **alle Sessions**
- ✅ Löscht **alle Sätze**

### Trainingstage löschen:

```swift
// In ManageWorkoutDaysView
.alert("Tag löschen?") {
    Button("Löschen", role: .destructive) {
        context.delete(day)
    }
} message: {
    Text("'\(day.name)' wird gelöscht. Alle Übungen und Sessions gehen verloren.")
}
```

### Übungen löschen:

```swift
// In WorkoutDayView
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        context.delete(exercise)
    } label: {
        Label("Löschen", systemImage: "trash")
    }
}
```

## 🛠️ Technische Details

### Neue Dateien:

#### 1. `ProgramManagementView.swift` (NEU!)

Zentrale Verwaltungsansicht mit:

```swift
struct ProgramManagementView: View {
    @Query(sort: \WorkoutProgram.createdAt, order: .reverse) 
    private var programs: [WorkoutProgram]
    
    var body: some View {
        // Liste aller Programme
        // Expandable Cards
        // Löschen-Funktion
        // Template-Integration
    }
}
```

#### 2. `ProgramManagementCard` (NEU!)

Expandable Card für jedes Programm:

```swift
struct ProgramManagementCard: View {
    @Bindable var program: WorkoutProgram
    @State private var showDetails = false
    
    var body: some View {
        // Header mit Icon + Name
        // Stats (Tage, Sessions)
        // Expandable Details
        // Trainingstage-Liste
        // Bearbeiten/Löschen Buttons
    }
}
```

### Geänderte Dateien:

#### 1. `HomeView.swift`

- ❌ Entfernt: `showPlanGenerator`
- ❌ Entfernt: Plan-Generator Button
- ✅ Vereinfacht: Nur noch Template + Eigenes Programm
- ✅ Template als "EMPFOHLEN" markiert

#### 2. `ProfileView.swift`

- ✅ Neu: `managementSection`
- ✅ Link zu `ProgramManagementView`
- ✅ Card mit Icon + Beschreibung

#### 3. `ManageWorkoutDaysView.swift`

- ✅ Bereits existiert
- ✅ Kann Trainingstage verwalten
- ✅ Bearbeiten + Löschen möglich

## 📊 Datenbank-Struktur

### Cascade Delete Regeln:

```swift
@Model final class WorkoutProgram {
    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.program)
    var days: [WorkoutDay] = []
}

@Model final class WorkoutDay {
    @Relationship(deleteRule: .cascade, inverse: \Exercise.day)
    var exercises: [Exercise] = []
}

@Model final class Exercise {
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet] = []
}
```

**Bedeutung:**
- Programm löschen → Löscht automatisch alle Tage
- Tag löschen → Löscht automatisch alle Übungen
- Übung löschen → Löscht automatisch alle Sätze

## 🎯 Beispiel-Flows

### Flow 1: Neues Programm via Template

```
1. Home → + Button → "Template nutzen"
2. Template auswählen (z.B. Push/Pull/Legs)
3. "Fertig" → Programm wird erstellt
4. Automatisch: 3 Trainingstage mit allen Übungen
5. Fertig! Training kann starten
```

### Flow 2: Programm löschen

```
1. Profil → "Programme verwalten"
2. Programm-Card öffnen (↓)
3. "Löschen" Button
4. Bestätigung: "Programm löschen?"
5. "Löschen" → Programm ist weg
```

### Flow 3: Übung bearbeiten

```
1. Trainingstag öffnen (z.B. "Push")
2. Übung nach links swipen
3. "Bearbeiten" Button
4. Name, Sätze, Wdh. ändern
5. "Speichern" → Fertig
```

### Flow 4: Trainingstag löschen

```
1. Trainingstage-Tab → "Trainingstage"
2. Tag auswählen → "..." Menü
3. "Löschen"
4. Bestätigung: "Tag löschen?"
5. "Löschen" → Tag ist weg
```

## ✅ Testing

### Test-Szenarien:

#### 1. **Programm erstellen via Template**
- Template wählen
- Programm wird erstellt
- Alle Trainingstage vorhanden
- Alle Übungen vorhanden
- ✅ Funktioniert

#### 2. **Programm löschen**
- Programm in Verwaltung löschen
- Bestätigung erscheint
- Nach Bestätigung: Programm weg
- Alle Tage weg
- Alle Übungen weg
- ✅ Cascade Delete funktioniert

#### 3. **Trainingstag löschen**
- Tag löschen
- Bestätigung erscheint
- Nach Bestätigung: Tag weg
- Übungen weg
- ✅ Funktioniert

#### 4. **Übung löschen**
- Swipe rechts
- Löschen
- Übung weg
- Sätze weg
- ✅ Funktioniert

#### 5. **Übung bearbeiten**
- Swipe links
- Bearbeiten
- Änderungen speichern
- ✅ Funktioniert

## 🚀 Zukünftige Erweiterungen

Mögliche weitere Verbesserungen:

- 📝 **Programm-Name bearbeiten**
- 🔄 **Trainingstage neu ordnen** (Drag & Drop)
- 📋 **Programm duplizieren**
- 📤 **Programm exportieren/teilen**
- 📥 **Programm importieren**
- 🎨 **Programm-Farben/Icons**
- 📊 **Programm-Statistiken** (Durchschnitt, etc.)
- ⭐ **Favoriten-System**

## 📝 Zusammenfassung

### Entfernt:
- ❌ Plan-Generator (zu komplex)
- ❌ Mehrstufiger Setup-Prozess

### Hinzugefügt:
- ✅ Zentrale Programm-Verwaltung
- ✅ Löschen-Funktionen für alles
- ✅ Expandable Programme-Cards
- ✅ Template als Hauptmethode
- ✅ Link in Profil

### Verbessert:
- ✅ Einfacherer Einstieg
- ✅ Klarere Navigation
- ✅ Mehr Kontrolle für Benutzer
- ✅ Weniger Code, mehr Features

---

**Stand:** 23. März 2026  
**Version:** 2.0 - Zentrale Programm-Verwaltung mit Template-System
