# 🎯 Automatische Phasen-Erkennung

## Übersicht

Das System erkennt **automatisch** die aktuelle Zyklus-Phase basierend auf dem Periodenkalender. Der Benutzer muss **keine manuelle Auswahl** mehr treffen.

## 🔄 Wie es funktioniert

### 1. **Kalender-Daten**
```swift
// CycleManager berechnet automatisch die aktuelle Phase
cycleManager.currentPhase  // → z.B. .follicular
cycleManager.currentCycleDay  // → z.B. 11
```

Der `CycleManager` nutzt:
- **Periode Start-Datum** (vom Benutzer im Kalender eingetragen)
- **Zyklus-Länge** (Standard: 28 Tage)
- **Perioden-Länge** (Standard: 5 Tage)

### 2. **Phasen-Berechnung**
```swift
var currentPhase: CyclePhase {
    let day = currentCycleDay
    
    if day <= periodLength {
        return .menstruation      // Tag 1-5 → 75% Gewichte
    } else if day <= 13 {
        return .follicular        // Tag 6-13 → 100% Gewichte ⚡
    } else if day <= 16 {
        return .ovulation         // Tag 14-16 → 98% Gewichte
    } else {
        return .luteal            // Tag 17-28 → 85% Gewichte
    }
}
```

### 3. **Automatischer Start**

Wenn der Benutzer ein Training startet:

```swift
func startWorkout(phase: CyclePhase? = nil) {
    // Verwendet AUTOMATISCH die aktuelle Phase
    let sessionPhase = phase ?? cycleManager.currentPhase
    
    // Erstellt Session mit Phase-Info
    let session = WorkoutSession(
        workoutDay: day,
        isDuringPeriod: sessionPhase == .menstruation,
        cyclePhase: sessionPhase  // ← Wird gespeichert!
    )
    
    // Zeigt Bestätigung an
    "Training gestartet in Follikelphase (100% Gewichte)" // Toast-Banner
}
```

## 📊 Was wird automatisch angepasst?

### Beim Training-Start:
- ✅ **Phase erkannt** aus Kalender (Tag 11 → Follikelphase)
- ✅ **Gewichte angepasst** (100% in Follikelphase)
- ✅ **Session gespeichert** mit Phase-Info
- ✅ **Toast-Banner** zeigt Bestätigung

### Beim Satz-Eintrag:
- ✅ **Gewichts-Vorschlag** basierend auf Phase
- ✅ **Automatische Skalierung** (z.B. 75% während Periode)
- ✅ **Phase gespeichert** in jedem WorkoutSet

```swift
// In ExerciseDetailView
let newSet = WorkoutSet(
    weight: weight,
    reps: reps,
    setNumber: todaySets.count + 1,
    isDuringPeriod: isInPeriod,
    note: noteInput,
    cyclePhase: cycleManager.currentPhase  // ← Automatisch!
)
```

## 🎨 UI-Feedback

### 1. **Info-Banner (immer sichtbar)**
```
┌─────────────────────────────────────┐
│ 📅 Automatisch erkannt              │
│ Tag 11 • Follikelphase              │
└─────────────────────────────────────┘
```

### 2. **Toast-Banner (beim Start, 3 Sekunden)**
```
┌─────────────────────────────────────┐
│ 🌱 Training gestartet!              │
│ Follikelphase • 100% Gewichte  ✓   │
└─────────────────────────────────────┘
```

### 3. **Phasen-Toggle (manueller Override)**
Der Benutzer kann die Phase **manuell ändern**, wenn nötig:
- Dropdown-Menü mit allen 4 Phasen
- Zeigt aktuelle Phase mit Checkmark
- Während Training gesperrt (🔒)

## 🔍 Vorteile

### Für den Benutzer:
- ✨ **Keine manuelle Eingabe** nötig
- 📅 **Immer korrekte Phase** basierend auf Kalender
- 🎯 **Optimale Gewichte** automatisch
- 💪 **Fokus aufs Training**, nicht auf Einstellungen

### Für die Daten-Qualität:
- 📊 **Konsistente Phase-Tracking** 
- 🔄 **Automatische Updates** bei Zyklus-Änderungen
- 📈 **Bessere Analyse** von Phase-spezifischen Fortschritten

## 🛠️ Technische Details

### Geänderte Dateien:

1. **`WorkoutDayView.swift`**
   - ❌ Alert für Phase-Auswahl entfernt
   - ✅ Automatische Phase-Erkennung beim Start
   - ✅ Toast-Banner für Feedback
   - ✅ Info-Banner zeigt aktuelle Phase

2. **`CycleManager.swift`**
   - ✅ `currentPhase` Property (berechnet automatisch)
   - ✅ `currentCycleDay` (1-28)
   - ✅ Phase-Logik mit 4 Phasen

3. **`Models.swift`**
   - ✅ `WorkoutSession` speichert `cyclePhase`
   - ✅ `WorkoutSet` speichert `cyclePhase`
   - ✅ `Exercise.suggestedWeight(for:)` für Phase-basierte Vorschläge

## 🎓 Beispiel-Ablauf

### Szenario: Benutzer startet Training am Tag 11

1. **System liest Kalender:**
   - Letzte Periode: 10 Tage her
   - Tag im Zyklus: 11
   - Phase: Follikelphase (Tag 6-13)

2. **Benutzer tippt "Start":**
   - Keine Nachfrage!
   - Training startet sofort
   - Phase: Follikelphase (100% Gewichte)

3. **Toast-Banner erscheint:**
   ```
   🌱 Training gestartet!
   Follikelphase • 100% Gewichte ✓
   ```

4. **Session wird gespeichert:**
   ```swift
   WorkoutSession {
       startTime: 2026-03-23 14:30:00
       cyclePhase: .follicular
       isDuringPeriod: false
   }
   ```

5. **Bei jedem Satz:**
   ```swift
   WorkoutSet {
       weight: 50.0 kg  // Voll-Gewicht (100%)
       reps: 10
       cyclePhase: .follicular
   }
   ```

## 🚀 Zukünftige Erweiterungen

Mögliche weitere Verbesserungen:

- 🔔 **Benachrichtigung** bei Phasen-Wechsel
- 📊 **Statistiken** pro Phase (Durchschnitts-Gewichte)
- 🎨 **Farb-Coding** in Workout-History
- 💡 **Tipps** basierend auf aktueller Phase
- 📈 **Trend-Analyse** über mehrere Zyklen

## ✅ Testing

### Test-Szenarien:

1. **Normale Phase (Follikelphase)**
   - Tag 8-13 → 100% Gewichte
   - Grüne Farbe (#1D9E75)
   - "Power!" Label

2. **Periode (Menstruation)**
   - Tag 1-5 → 75% Gewichte
   - Pink Farbe (#E84393)
   - "Schonend" Label

3. **Ovulation**
   - Tag 14-16 → 98% Gewichte
   - Gold/Orange (#F4A623)
   - "Peak" Label

4. **Lutealphase**
   - Tag 17-28 → 85% Gewichte
   - Lila (#7B68EE)
   - "Moderat" Label

---

**Stand:** 23. März 2026  
**Version:** 2.0 - Vollautomatische Phasen-Erkennung
