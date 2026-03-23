# 🔄 Fix: Nächstes Training - Synchronisation zwischen Home & Workouts-Tab

## Problem

**Vorher:**
```
Home-Tab (Mein Programm):
- Push (Brust, Schultern, Trizeps)
- Pull (Rücken, Bizeps)
- Legs (Beine)

Workouts-Tab (Nächstes Training):
- Push  ← Immer nur das erste unvollständige
```

❌ **Nicht synchronisiert!**
- Home zeigt ALLE Trainingstage
- Workouts zeigt nur das erste unvollständige Training
- Ignoriert den Wochenplan

## Lösung

**Nachher:**
```
Intelligente Auswahl basierend auf:
1. Heutiger Wochentag (z.B. Montag = Push)
2. Wochenplan aus PlanGenerator
3. Fallback: Nächster geplanter Tag
4. Fallback: Erstes Training
```

## 🎯 Neue Logik

### Prioritäten-System:

```swift
func determineNextWorkout(for program: WorkoutProgram) -> WorkoutDay? {
    // 1. Heute geplant? (z.B. Montag = Push)
    if let todayWorkout = program.workoutDay(for: today) {
        return todayWorkout  // ✅ Push (weil heute Montag)
    }
    
    // 2. Nächster geplanter Tag? (z.B. Mittwoch = Pull)
    for offset in 1...7 {
        if let nextWorkout = program.workoutDay(for: nextWeekday) {
            return nextWorkout  // ✅ Pull (weil Mittwoch nächster Plan-Tag)
        }
    }
    
    // 3. Erstes unvollständiges Training?
    if let unfinished = program.sortedDays.first(where: { $0.completionPercent < 1.0 }) {
        return unfinished
    }
    
    // 4. Fallback: Erstes Training
    return program.sortedDays.first
}
```

## 📱 Beispiel-Szenarien

### Szenario 1: Push/Pull/Legs (Mo/Mi/Fr)

**Wochenplan:**
- Montag: Push
- Mittwoch: Pull  
- Freitag: Legs

**Heute ist Montag:**
```
Workouts-Tab zeigt:
→ Push (Brust, Schultern, Trizeps)
   ✓ Heute geplant!
```

**Heute ist Dienstag:**
```
Workouts-Tab zeigt:
→ Pull (Rücken, Bizeps)
   ✓ Nächster geplanter Tag: Mittwoch
```

**Heute ist Donnerstag:**
```
Workouts-Tab zeigt:
→ Legs (Beine)
   ✓ Nächster geplanter Tag: Freitag
```

### Szenario 2: Kein Wochenplan gesetzt

**Fallback-Logik:**
```
1. Erstes unvollständiges Training (< 100%)
   → z.B. Pull (50% fertig)

2. Wenn alle fertig: Erstes Training
   → z.B. Push
```

## 🎨 UI-Verbesserungen

### Vorher:
```
┌─────────────────────────────────────┐
│ Nächstes Training                   │
│                                     │
│ ○ Push                              │
│   3 Übungen · 💪 Normal-Gewichte    │
└─────────────────────────────────────┘
```

### Nachher:
```
┌─────────────────────────────────────┐
│ Nächstes Training                   │
│                                     │
│ ○ Push                              │
│   3 Übungen • 🌱 Power!             │
│              (Follikelphase)        │
└─────────────────────────────────────┘
```

**Neue Features:**
- ✅ Zeigt aktuelle Zyklus-Phase (🌱 Follikelphase)
- ✅ Zeigt Phase-Status ("Power!", "Schonend", etc.)
- ✅ Verwendet gleichen Emoji wie CycleManager

## 🛠️ Technische Details

### Geänderte Datei: `DashboardView.swift`

#### 1. **Neue Funktion: `determineNextWorkout()`**

```swift
func determineNextWorkout(for program: WorkoutProgram) -> WorkoutDay? {
    let today = Weekday.from(date: Date())
    
    // Prüfe Wochenplan
    if let todayWorkout = program.workoutDay(for: today) {
        return todayWorkout
    }
    
    // Nächster geplanter Tag
    for offset in 1...7 {
        let nextWeekday = weekdays[(todayIndex + offset) % weekdays.count]
        if let workout = program.workoutDay(for: nextWeekday) {
            return workout
        }
    }
    
    // Fallbacks...
}
```

#### 2. **Verbesserte UI-Anzeige**

```swift
// Vorher:
Text("\(nextDay.exercises.count) Übungen · \(cycleManager.isInPeriod ? "🌸" : "💪")")

// Nachher:
HStack(spacing: 8) {
    Text("\(nextDay.exercises.count) Übungen")
    Text("•")
    HStack(spacing: 4) {
        Text(cycleManager.currentPhase.emoji)  // 🌱
        Text(cycleManager.currentPhase.shortDescription)  // "Power!"
            .foregroundColor(cycleManager.currentPhase.color)
    }
}
```

### Integration mit Models

#### `WorkoutProgram` nutzt:
```swift
var scheduledDays: [Weekday: Int] {
    // z.B. ["Mon": 0, "Wed": 1, "Fri": 2]
}

func workoutDay(for weekday: Weekday) -> WorkoutDay? {
    // Gibt den Trainingstag für einen Wochentag zurück
}
```

#### `Weekday` Enum:
```swift
enum Weekday: String, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    static func from(date: Date) -> Weekday {
        // Konvertiert Datum zu Wochentag
    }
}
```

## ✅ Testing

### Test-Fälle:

#### 1. **Mit Wochenplan (Push/Pull/Legs)**
```swift
Montag → Push ✓
Dienstag → Pull (nächster geplanter Tag) ✓
Mittwoch → Pull ✓
Donnerstag → Legs (nächster geplanter Tag) ✓
Freitag → Legs ✓
Samstag → Push (nächster geplanter Tag = Montag) ✓
```

#### 2. **Ohne Wochenplan**
```swift
Immer → Erstes unvollständiges Training ✓
Wenn alle fertig → Erstes Training ✓
```

#### 3. **Leeres Programm**
```swift
Zeigt: "Keine Trainingstage vorhanden" ✓
```

## 🔄 Synchronisation

### Jetzt synchronisiert:

```
┌─────────────────────────────────────┐
│ HOME-TAB                            │
│ Mein Programm:                      │
│ • Push ← Heute geplant!             │
│ • Pull                              │
│ • Legs                              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ WORKOUTS-TAB                        │
│ Nächstes Training:                  │
│ • Push ← Gleicher Tag! ✓            │
└─────────────────────────────────────┘
```

## 📊 Vorteile

### Für den Benutzer:
- ✅ **Konsistente Anzeige** in beiden Tabs
- ✅ **Intelligente Vorschläge** basierend auf Wochenplan
- ✅ **Klare Phase-Info** (Follikelphase, Menstruation, etc.)
- ✅ **Bessere Orientierung** ("Heute ist Push-Tag!")

### Technisch:
- ✅ **Wiederverwendbare Logik** (`determineNextWorkout()`)
- ✅ **Nutzt bestehenden Wochenplan** vom PlanGenerator
- ✅ **Fallback-System** für Flexibilität
- ✅ **Integration mit CycleManager**

## 🚀 Zukünftige Erweiterungen

Mögliche Verbesserungen:

- 📅 **Kalender-Integration**: "Heute ist dein Push-Tag!"
- 🔔 **Erinnerungen**: Benachrichtigung für geplante Trainingstage
- 📊 **Wochenansicht**: Alle geplanten Trainings dieser Woche
- 🎯 **Smart-Suggestions**: "Du hast Pull diese Woche übersprungen"
- 📈 **Streak-Tracking**: "3 Wochen Push/Pull/Legs durchgezogen!"

---

**Stand:** 23. März 2026  
**Version:** 2.0 - Intelligente Trainingstag-Auswahl mit Wochenplan-Integration
