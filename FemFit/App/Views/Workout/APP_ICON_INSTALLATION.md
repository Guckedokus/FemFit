# 🎨 App-Icon Installation

## Schritt-für-Schritt Anleitung

### 1. **Icon-Größen vorbereiten**

Du brauchst das Icon in verschiedenen Größen für iOS:

| Größe | Verwendung | Dateiname |
|-------|-----------|-----------|
| 1024x1024 | App Store | AppIcon.png |
| 180x180 | iPhone (3x) | AppIcon-60@3x.png |
| 120x120 | iPhone (2x) | AppIcon-60@2x.png |
| 87x87 | Settings (3x) | AppIcon-29@3x.png |
| 58x58 | Settings (2x) | AppIcon-29@2x.png |
| 80x80 | Spotlight (2x) | AppIcon-40@2x.png |
| 120x120 | Spotlight (3x) | AppIcon-40@3x.png |

### 2. **In Xcode hinzufügen**

#### Option A: Automatisch (empfohlen)
1. Öffne dein Projekt in Xcode
2. Navigiere zu **Assets.xcassets**
3. Klicke auf **AppIcon**
4. Ziehe das 1024x1024 Bild in das große Feld
5. Xcode generiert automatisch alle Größen ✨

#### Option B: Manuell
1. Öffne **Assets.xcassets**
2. Klicke auf **AppIcon**
3. Ziehe jede Größe in das entsprechende Feld

### 3. **Xcode-Pfad**

```
FemFit/
├── FemFit/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   │   ├── Contents.json
│   │   │   ├── AppIcon-60@2x.png (120x120)
│   │   │   ├── AppIcon-60@3x.png (180x180)
│   │   │   ├── AppIcon-1024.png (1024x1024)
│   │   │   └── ... (weitere Größen)
```

### 4. **Schnell-Lösung: Online Tool**

Nutze ein Tool wie **appicon.co**:
1. Gehe zu https://www.appicon.co
2. Lade dein 1024x1024 Bild hoch
3. Download die ZIP mit allen Größen
4. Ziehe den Inhalt in Xcode's AppIcon

### 5. **Contents.json Beispiel**

Falls du es manuell machst, sollte die `Contents.json` so aussehen:

```json
{
  "images" : [
    {
      "filename" : "AppIcon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### 6. **Design-Tipps für dein Logo**

✅ **Perfekt für dein FemFit Logo:**
- Pink-Lila Gradient (#E84393 → #7B68EE) ✓
- Frau mit Hantel (zeigt Fitness + Weiblichkeit) ✓
- Saubere Silhouette (gut erkennbar auf kleinen Größen) ✓
- Abgerundete Ecken (iOS-Standard) ✓

⚠️ **Wichtig:**
- Keine Transparenz im Hintergrund
- Gradient sollte auch bei 60x60 gut aussehen
- Text "FemFit" im Icon ist optional (meist besser ohne)

### 7. **Testen**

Nach dem Hinzufügen:
1. **Clean Build Folder**: Cmd + Shift + K
2. **Rebuild**: Cmd + B
3. **Run**: Cmd + R
4. Prüfe auf dem Home-Screen deines Test-Geräts

### 8. **Alternative: SwiftUI Asset Catalog**

Seit iOS 14 kannst du auch programmatisch auf Icons zugreifen:

```swift
// Für alternative Icons (später)
struct AlternateIcons {
    static let pride = "AppIcon-Pride"
    static let dark = "AppIcon-Dark"
}
```

---

## 🎨 Dein FemFit Logo - Perfekt!

Das Logo hat bereits:
- ✅ Klare Silhouette
- ✅ Passende Farben (Pink-Lila wie in der App)
- ✅ Feminine & starke Ausstrahlung
- ✅ iOS-kompatibles Format

---

**Nächste Schritte:**
1. Icon in 1024x1024 exportieren
2. In Xcode's AppIcon ziehen
3. App builden
4. Auf dem Home-Screen bewundern! 🎉
