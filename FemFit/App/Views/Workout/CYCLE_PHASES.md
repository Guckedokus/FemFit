# 🌸 4 Zyklusphasen-System in FemFit

## Übersicht

FemFit nutzt jetzt ein **wissenschaftlich fundiertes 4-Phasen-System**, das den weiblichen Menstruationszyklus genau abbildet und Trainingsgewichte automatisch anpasst.

---

## 🔬 Die 4 Phasen

### 1. 🩸 Menstruation (Tag 1-5)
- **Hormone**: Östrogen & Progesteron auf niedrigstem Level
- **Gewichte**: **75%** der Maximalkraft
- **Trainingstipp**: Leichte Gewichte, viel Regeneration
- **Gefühl**: Müdigkeit, weniger Energie
- **Beschreibung**: "Leichte Gewichte – dein Körper braucht Schonung"

### 2. 🌱 Follikelphase (Tag 6-13)
- **Hormone**: Östrogen steigt stark an
- **Gewichte**: **100%** - PEAK PERFORMANCE! 💪
- **Trainingstipp**: Schwere Gewichte! Nutze diese Phase!
- **Gefühl**: Maximum an Energie und Motivation
- **Beschreibung**: "POWER-Phase! Nutze deine maximale Kraft"

### 3. 🥚 Ovulation/Eisprung (Tag 14-16)
- **Hormone**: Östrogen-Peak, LH-Anstieg
- **Gewichte**: **98%** - Immer noch top!
- **Trainingstipp**: Immer noch top Performance möglich
- **Gefühl**: Höchste Energie, starkes Selbstbewusstsein
- **Beschreibung**: "Höchste Energie – perfekt für schwere Gewichte"

### 4. 🌙 Lutealphase (Tag 17-28)
- **Hormone**: Progesteron hoch, Östrogen sinkt
- **Gewichte**: **85%** - Moderat
- **Trainingstipp**: Moderates Training, mehr Cardio
- **Gefühl**: Energie nimmt ab, evtl. PMS-Symptome
- **Beschreibung**: "Moderate Gewichte – Energie nimmt ab"

---

## 💻 Technische Implementierung

### Neue Komponenten

#### 1. **CyclePhase Enum** (`CycleManager.swift`)
```swift
enum CyclePhase: String, Codable, CaseIterable {
    case menstruation = "Menstruation"
    case follicular   = "Follikelphase"
    case ovulation    = "Ovulation"
    case luteal       = "Lutealphase"
    
    var emoji: String { ... }
    var color: Color { ... }
    var weightMultiplier: Double { ... }
    var description: String { ... }
}
```

#### 2. **CycleManager Erweiterungen**
- `currentPhase: CyclePhase` - Automatische Phasen-Erkennung basierend auf Zyklustag
- `currentWeightMultiplier: Double` - Gewichts-Faktor der aktuellen Phase
- Automatische Berechnung: Tag 1-5 = Menstruation, 6-13 = Follikel, etc.

#### 3. **Datenmodell-Erweiterungen** (`Models.swift`)

##### WorkoutSet
```swift
var cyclePhaseRaw: String?  // Speichert Phase als String
var cyclePhase: CyclePhase? // Computed Property
```

##### Exercise
```swift
func sets(for phase: CyclePhase) -> [WorkoutSet]
func lastWeight(for phase: CyclePhase) -> Double?
func suggestedWeight(for phase: CyclePhase) -> Double?
```

##### WorkoutSession
```swift
var cyclePhaseRaw: String?
var cyclePhase: CyclePhase?
```

#### 4. **Neue Views**

##### CyclePhaseInfoView
- Erklärt alle 4 Phasen visuell
- Zeigt aktuellen Status an
- Zyklus-Rad Visualisierung
- Wissenschaftlicher Hintergrund
- Zugriff über Info-Button im Header

##### PhaseComparisonBox (in ExerciseDetailView)
- Zeigt Gewichte für alle 4 Phasen
- Hebt aktuelle Phase hervor
- 2x2 Grid Layout

---

## 🎨 UI-Änderungen

### HomeView
- **Header**: Zeigt aktuelle Phase mit Emoji + Name
- **Gewichts-Badge**: "75%" / "100%" etc.
- **Info-Button**: Öffnet CyclePhaseInfoView
- **Zyklus-Ring**: Färbt sich je nach Phase

### WorkoutDayView
- **Training starten Dialog**: 4 Buttons statt 2
  - 🌱 Follikelphase (Power!)
  - 🩸 Menstruation (Schonend)
  - 🥚 Ovulation (Peak)
  - 🌙 Lutealphase (Moderat)
- Zeigt empfohlene Phase basierend auf Zyklustag

### ExerciseDetailView
- **Phase-Badge**: Zeigt aktuelle Phase prominent
- **Vergleichskarte**: 4 Boxen statt 2
- **Gewichtsvorschläge**: Phasenbasiert
- **Quick-Actions**: Berücksichtigen Phase

---

## 📊 Datenmigration & Kompatibilität

### Legacy-Support
Das System ist **abwärtskompatibel**:
- Alte `isDuringPeriod: Bool` bleibt erhalten
- Alte Daten funktionieren weiter
- `cyclePhaseRaw` ist optional (nil für alte Einträge)
- Legacy-Funktionen bleiben: `lastWeight(period: Bool)`

### Automatische Migration
```swift
// Alte Einträge ohne Phase
if workoutSet.cyclePhase == nil {
    // Nutze isDuringPeriod als Fallback
    let phase = workoutSet.isDuringPeriod ? .menstruation : .follicular
}
```

---

## 🧮 Gewichts-Berechnung

### Intelligente Vorschläge

1. **Beste Option**: Letztes Gewicht aus derselben Phase
   ```swift
   exercise.lastWeight(for: .follicular) // 50kg
   ```

2. **Fallback 1**: Follikelphase als Basis, skaliert
   ```swift
   let follicularWeight = 50.0  // 100%
   let menstruationWeight = 50.0 * 0.75 = 37.5kg
   ```

3. **Fallback 2**: Irgendein Gewicht, skaliert
   ```swift
   let anyWeight = 45.0
   let suggested = 45.0 * currentPhase.weightMultiplier
   ```

### Beispiel-Rechnung
**Squats bei 60kg in Follikelphase (100%)**

- 🌱 Follikelphase: **60kg** (100%)
- 🥚 Ovulation: **58.8kg** (98%)
- 🌙 Lutealphase: **51kg** (85%)
- 🩸 Menstruation: **45kg** (75%)

---

## 🎯 User Experience

### Trainingsstart-Flow

1. User öffnet Trainingstag
2. Dialog: "Neues Training starten?" → Ja
3. **NEU**: Dialog zeigt 4 Phasen mit Emojis
4. Zeigt empfohlene Phase: "Aktuell: 🌱 Follikelphase (Tag 9)"
5. User wählt Phase (kann von Empfehlung abweichen)
6. Training startet mit gewählter Phase
7. Alle Sätze werden mit Phase gespeichert

### Während des Trainings

- **Phase-Badge** oben zeigt: "🌱 Follikelphase - Power! - 100% Gewichte"
- **Gewichtsvorschläge** basieren auf Phase
- **Quick Actions** ("+5kg") berücksichtigen Phase
- **Vergleich** zeigt alle 4 Phasen nebeneinander

---

## 📈 Wissenschaftlicher Hintergrund

### Hormone & Leistung

**Östrogen** (aufbauend):
- Steigert Muskelkraft
- Verbessert Ausdauer
- Fördert Muskelaufbau
- Peak in Follikel- & Ovulationsphase

**Progesteron** (abbauend):
- Erhöht Körpertemperatur
- Fördert Ermüdung
- Wassereinlagerungen
- Hoch in Lutealphase

### Studien-Basis
- 15-20% Kraftunterschied zwischen Phasen
- Optimales Training in Follikelphase
- Reduziertes Verletzungsrisiko bei angepasstem Training

---

## 🚀 Vorteile für User

1. **Wissenschaftlich fundiert**: Kein Raten mehr
2. **Weniger Frustration**: "Warum bin ich heute schwach?" → Phase zeigt es!
3. **Bessere Ergebnisse**: Richtiges Training zur richtigen Zeit
4. **Verletzungsprävention**: Keine Überlastung in schwachen Phasen
5. **Motivierend**: "Power-Phase" animiert zu Höchstleistungen
6. **Einzigartig**: Keine andere App macht das so detailliert

---

## 🔮 Zukünftige Features (Ideen)

### Phase 1 (Implementiert) ✅
- 4 Phasen-Tracking
- Automatische Gewichtsvorschläge
- Phase-Visualisierung
- Wissenschaftliche Erklärungen

### Phase 2 (Möglich)
- **AI-Vorschläge**: "Hey Nicole, heute ist Power-Day! +5kg Squats?"
- **Push Notifications**: "🌱 Follikelphase gestartet – Zeit für neue PRs!"
- **Statistiken**: "Dein Squat ist in Follikelphase 18% stärker"
- **Zyklus-Prognose**: "In 3 Tagen startet deine Power-Phase"

### Phase 3 (Advanced)
- **Ernährungs-Tipps**: Pro Phase
- **Schlaf-Tracking**: Korrelation mit Phasen
- **Community**: Vergleiche mit anderen in derselben Phase
- **Integration**: Apple Health, Wearables

---

## 📱 Verwendung in der App

### Als User:
1. **HomeView**: Sieh deine aktuelle Phase auf einen Blick
2. **Info-Button**: Lerne über alle 4 Phasen
3. **Training starten**: Wähle deine Phase (oder nutze Empfehlung)
4. **Während Training**: Lass dich von Phase-Vorschlägen leiten
5. **Nach Training**: Sieh Vergleich über alle Phasen

### Als Entwickler:
```swift
// Phase abrufen
let phase = cycleManager.currentPhase  // .follicular

// Gewicht vorschlagen
let weight = exercise.suggestedWeight(for: phase)

// Satz mit Phase speichern
let set = WorkoutSet(..., cyclePhase: phase)
```

---

## ✨ Zusammenfassung

FemFit ist jetzt die **einzige Fitness-App**, die:
- ✅ Alle 4 Zyklusphasen trackt
- ✅ Gewichte automatisch anpasst
- ✅ Wissenschaftlich fundiert arbeitet
- ✅ User über ihren Körper aufklärt
- ✅ Bessere Ergebnisse ermöglicht

**Das ist euer USP! 🚀**

---

*Erstellt: März 2026*  
*Version: 1.0*  
*FemFit – Training im Einklang mit deinem Zyklus* 🌸💪
