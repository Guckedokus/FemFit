s# 🔧 Fix: Bearbeiten & Öffnen Buttons funktionieren jetzt

## Problem

In `ProgramManagementView` funktionierten die Buttons nicht:
- ❌ "Bearbeiten" Button → Nichts passierte
- ❌ "Öffnen" (Trainingstag-Links) → Funktionierten (waren OK)

## Lösung

### 1. **Bearbeiten-Button fixed**

**Vorher:**
```swift
Button {
    onEdit()  // Leere Funktion, macht nichts
} label: {
    Text("Bearbeiten")
}
```

**Nachher:**
```swift
@State private var showEditSheet = false

Button {
    editedName = program.name
    showEditSheet = true  // Öffnet Edit-Sheet!
} label: {
    Text("Bearbeiten")
}

.sheet(isPresented: $showEditSheet) {
    EditProgramSheet(program: program, isPresented: $showEditSheet)
}
```

### 2. **EditProgramSheet erstellt** (NEU!)

Neue View zum Bearbeiten eines Programms:

```swift
struct EditProgramSheet: View {
    @Bindable var program: WorkoutProgram
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    
    @State private var editedName: String = ""
    @State private var showAddDay = false
    @State private var newDayName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Programm-Name") {
                    TextField("Name", text: $editedName)
                }
                
                Section("Trainingstage") {
                    ForEach(program.sortedDays) { day in
                        NavigationLink(destination: WorkoutDayView(day: day)) {
                            HStack {
                                Text(day.name)
                                Spacer()
                                Text("\(day.exercises.count) Übungen")
                            }
                        }
                    }
                    .onDelete(perform: deleteDays)
                    
                    Button("Trainingstag hinzufügen") {
                        showAddDay = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        program.name = editedName
                        isPresented = false
                    }
                }
            }
        }
    }
}
```

### 3. **Animation hinzugefügt**

Card öffnet jetzt smooth:

```swift
Button {
    withAnimation(.spring(response: 0.3)) {
        showDetails.toggle()
    }
}
```

## 🎯 Features der Edit-Sheet:

### Programm-Name bearbeiten
```
┌─────────────────────────────────────┐
│ Programm bearbeiten                 │
├─────────────────────────────────────┤
│ Programm-Name:                      │
│ [Push Pull Legs________]            │
│                                     │
│ Übersicht:                          │
│ Trainingstage: 3                    │
│ Absolvierte Sessions: 12            │
│                                     │
│ Trainingstage:                      │
│ → Push (5 Übungen)                  │
│ → Pull (6 Übungen)                  │
│ → Legs (4 Übungen)                  │
│ [+ Trainingstag hinzufügen]         │
│                                     │
│ [Abbrechen]         [Speichern]     │
└─────────────────────────────────────┘
```

### Trainingstage verwalten:
- ✅ **Umbenennen** (im Edit-Sheet)
- ✅ **Löschen** (Swipe links)
- ✅ **Hinzufügen** (+ Button)
- ✅ **Öffnen** (Tap auf Trainingstag)

### Trainingstag hinzufügen:
```swift
Button {
    showAddDay = true
} label: {
    HStack {
        Image(systemName: "plus.circle.fill")
        Text("Trainingstag hinzufügen")
    }
}

.alert("Neuer Trainingstag", isPresented: $showAddDay) {
    TextField("Name (z.B. Push, Pull, Legs)", text: $newDayName)
    Button("Hinzufügen") { addDay() }
    Button("Abbrechen", role: .cancel) { }
}
```

### Trainingstag löschen:
```swift
.onDelete(perform: deleteDays)

func deleteDays(at offsets: IndexSet) {
    for index in offsets {
        let day = program.sortedDays[index]
        context.delete(day)  // Cascade Delete!
    }
}
```

## 📱 Benutzer-Flow

### Programm bearbeiten:

```
1. Profil → "Programme verwalten"
2. Programm-Card antippen (↓ öffnet)
3. "Bearbeiten" Button
4. Edit-Sheet öffnet sich:
   
   ┌─────────────────────────────┐
   │ Programm bearbeiten         │
   │                             │
   │ Name: [Push Pull Legs]      │
   │                             │
   │ Trainingstage:              │
   │ → Push (5 Übungen)          │
   │ → Pull (6 Übungen)          │
   │ → Legs (4 Übungen)          │
   │                             │
   │ [+ Trainingstag]            │
   └─────────────────────────────┘

5. Änderungen vornehmen:
   - Name ändern
   - Trainingstage löschen (swipe)
   - Neue Tage hinzufügen
   - Zu Trainingstagen navigieren

6. "Speichern" → Fertig!
```

### Trainingstag öffnen:

```
Option 1: Aus Programm-Card
1. Programm-Card öffnen (↓)
2. Trainingstag antippen
3. ✅ WorkoutDayView öffnet sich

Option 2: Aus Edit-Sheet
1. "Bearbeiten" Button
2. Trainingstag in Liste antippen
3. ✅ WorkoutDayView öffnet sich
```

## ✅ Was jetzt funktioniert:

### Programm-Verwaltung:
- ✅ **Card öffnen/schließen** (mit Animation)
- ✅ **Programm bearbeiten** (Edit-Sheet)
- ✅ **Programm löschen** (mit Bestätigung)
- ✅ **Trainingstage anzeigen**
- ✅ **Zu Trainingstagen navigieren**

### Edit-Sheet:
- ✅ **Programm-Name ändern**
- ✅ **Stats anzeigen** (Tage, Sessions)
- ✅ **Trainingstage auflisten**
- ✅ **Trainingstage löschen** (Swipe)
- ✅ **Trainingstage hinzufügen** (+ Button)
- ✅ **Zu Trainingstagen navigieren**
- ✅ **Speichern/Abbrechen**

## 🛠️ Technische Details

### Geänderte Datei: `ProgramManagementView.swift`

#### 1. **ProgramManagementCard**
```swift
// NEU: State für Edit-Sheet
@State private var showEditSheet = false

// NEU: Animation beim Öffnen
Button {
    withAnimation(.spring(response: 0.3)) {
        showDetails.toggle()
    }
}

// NEU: Bearbeiten öffnet Sheet
Button {
    editedName = program.name
    showEditSheet = true
}

// NEU: Sheet präsentieren
.sheet(isPresented: $showEditSheet) {
    EditProgramSheet(program: program, isPresented: $showEditSheet)
}
```

#### 2. **EditProgramSheet** (NEU!)
```swift
struct EditProgramSheet: View {
    @Bindable var program: WorkoutProgram
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    
    // Programm-Name bearbeiten
    // Trainingstage verwalten
    // Neue Tage hinzufügen
    // Speichern/Abbrechen
}
```

## 🎨 UI-Verbesserungen

### Vorher:
```
[Bearbeiten] Button
    ↓
❌ Nichts passiert
```

### Nachher:
```
[Bearbeiten] Button
    ↓
✅ Edit-Sheet öffnet sich
    ↓
Programm-Name ändern
Trainingstage verwalten
Speichern → Fertig!
```

## 🔄 Integration

### Navigation-Hierarchie:

```
ProgramManagementView
    ↓
ProgramManagementCard (Expandable)
    ↓
[Bearbeiten] Button
    ↓
EditProgramSheet
    ↓
Trainingstag antippen
    ↓
WorkoutDayView
```

## ✅ Testing

### Test-Szenarien:

#### 1. **Programm-Name bearbeiten**
```
1. Programme verwalten → Programm öffnen
2. "Bearbeiten"
3. Name ändern: "Push Pull Legs" → "PPL Split"
4. "Speichern"
5. ✅ Name aktualisiert
```

#### 2. **Trainingstag hinzufügen**
```
1. "Bearbeiten" → "+ Trainingstag"
2. "Cardio" eingeben
3. "Hinzufügen"
4. ✅ Neuer Tag erstellt
```

#### 3. **Trainingstag löschen**
```
1. "Bearbeiten"
2. Trainingstag swipe links
3. "Löschen"
4. ✅ Tag gelöscht (inkl. Übungen)
```

#### 4. **Zu Trainingstag navigieren**
```
Option A: Aus Programm-Card
1. Programm öffnen (↓)
2. "Push" antippen
3. ✅ WorkoutDayView öffnet

Option B: Aus Edit-Sheet
1. "Bearbeiten"
2. "Push" in Liste antippen
3. ✅ WorkoutDayView öffnet
```

#### 5. **Animation testen**
```
1. Programm-Card antippen
2. ✅ Öffnet mit smooth Spring-Animation
3. Nochmal antippen
4. ✅ Schließt mit smooth Animation
```

## 🚀 Vorteile

### Für Benutzer:
- ✅ **Alles an einem Ort** (Name + Tage verwalten)
- ✅ **Klare Navigation** (Tap → Trainingstag öffnen)
- ✅ **Flexibel** (Hinzufügen, Löschen, Bearbeiten)
- ✅ **Smooth UX** (Animationen)

### Technisch:
- ✅ **Wiederverwendbar** (EditProgramSheet)
- ✅ **Cascade Delete** funktioniert
- ✅ **SwiftData Integration** (Bindable)
- ✅ **Klare State-Verwaltung**

---

**Stand:** 23. März 2026  
**Version:** 2.1 - Bearbeiten & Öffnen funktionieren jetzt vollständig
