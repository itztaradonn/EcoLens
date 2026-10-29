# 🌿 EcoLens - AI Trash Classification App

> **Scan trash with your camera and instantly know if it's biodegradable or not!**

EcoLens is a SwiftUI iOS app that uses Apple's **FastViT-T8** CoreML model to classify trash items through image recognition and determine their biodegradability.

---

## ✨ Features

- 📸 **Camera Scanning** — Take a photo of any trash item for instant classification
- 🖼️ **Photo Library** — Choose existing photos to analyze
- 🧠 **AI-Powered** — Uses Apple FastViT-T8 (ImageNet-1k) for accurate object detection
- 🌱 **Biodegradability Mapping** — Maps 200+ object types to biodegradable / non-biodegradable
- ⏱️ **Decomposition Timeline** — Shows estimated decomposition time for each item
- 💡 **Disposal Tips** — Provides proper disposal and recycling recommendations
- 🌍 **Environmental Impact** — Explains the environmental consequences
- 📊 **Scan History** — Track all your scans with statistics and eco-score
- 🎨 **Premium Dark UI** — Beautiful eco-themed interface with animations

---

## 🔧 Setup Instructions

### Prerequisites
- **Mac** with **Xcode 15+** installed
- **iOS 17+** device (camera required for full functionality)
- **Apple Developer Account** (free tier works for testing)

### Step 1: Create Xcode Project
1. Open Xcode
2. File → New → Project
3. Choose **iOS → App**
4. Configure:
   - Product Name: `EcoLens`
   - Team: Your Apple ID
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
5. Save to a location on your Mac

### Step 2: Add Source Files
1. Delete the default `ContentView.swift` that Xcode created
2. Copy all the Swift files from this project into your Xcode project:

```
EcoLens/
├── EcoLensApp.swift
├── Info.plist
├── Models/
│   ├── ImageClassifier.swift
│   └── TrashCategories.swift
├── Views/
│   ├── ContentView.swift
│   ├── CameraView.swift
│   ├── ResultView.swift
│   └── HistoryView.swift
├── ViewModels/
│   └── ClassificationViewModel.swift
├── Utils/
│   └── Extensions.swift
└── SamplePhotos/
    ├── sample_plastic_bottle.png
    ├── sample_banana_peel.png
    ├── sample_paper_waste.png
    └── sample_metal_cans.png
```

3. Drag all folders into the Xcode project navigator
4. Make sure "Copy items if needed" is checked
5. Also delete the default `EcoLensApp.swift` that Xcode created (we have our own)

### Step 3: Add the FastViT-T8 Model
The model has been downloaded to the `FastViTT8/` folder.

1. Find `FastViTT8/FastViTT8F16.mlpackage` in Finder
2. Drag it into your Xcode project navigator (root level)
3. Check "Copy items if needed"
4. Xcode will auto-generate a `FastViTT8F16` Swift class

> ⚠️ If you need to re-download the model:
> ```bash
> pip install huggingface_hub
> python -c "from huggingface_hub import snapshot_download; snapshot_download('apple/coreml-FastViT-T8', local_dir='./FastViTT8')"
> ```

### Step 4: Configure Info.plist
If Xcode doesn't auto-detect the `Info.plist`:
1. Click your project in the navigator
2. Select the **EcoLens** target
3. Go to the **Info** tab
4. Add these keys manually if not present:
   - `Privacy - Camera Usage Description`: "EcoLens needs camera access to scan and classify trash items"
   - `Privacy - Photo Library Usage Description`: "EcoLens needs photo library access to classify trash from your photos"

### Step 5: Build & Run
1. Select your **physical iOS device** (camera doesn't work on Simulator)
2. Press **Cmd + R** to build and run
3. Trust the developer certificate on your device:
   - Settings → General → VPN & Device Management → Trust

---

## 🧠 How It Works

```
📸 User takes photo
    ↓
🔄 Image preprocessed (center-crop to 256×256)
    ↓
🤖 FastViT-T8 CoreML model classifies image
    ↓
🏷️ Returns ImageNet label (e.g., "water_bottle", "banana")
    ↓
🗂️ TrashCategoryMapper looks up label
    ↓
🌱 Returns: Biodegradable / Non-Biodegradable / Unknown
    + Decomposition time
    + Disposal tips
    + Environmental impact
```

### FastViT-T8 Model
- **Architecture**: Fast Hybrid Vision Transformer
- **Dataset**: Trained on ImageNet-1k (1000 categories)
- **Format**: CoreML `.mlpackage` (FP16)
- **Size**: ~8MB
- **Speed**: Real-time inference on iPhone

### Category Mapping
Since FastViT-T8 outputs ImageNet labels (e.g., "water_bottle"), we maintain a comprehensive mapping of **200+ labels** to biodegradability categories:

| Category | Examples | Decomposition |
|----------|----------|--------------|
| 🌱 Biodegradable | Banana, apple, newspaper, cardboard, cotton | Days to months |
| ⚠️ Non-Biodegradable | Plastic bottle, aluminum can, styrofoam, electronics | Years to never |
| ❓ Unknown | Items not in our mapping database | Consult local guidelines |

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `EcoLensApp.swift` | App entry point, dark theme setup |
| `ImageClassifier.swift` | CoreML + Vision framework wrapper |
| `TrashCategories.swift` | ImageNet → biodegradable mapping (200+ items) |
| `ContentView.swift` | Home screen with hero, stats, scan button |
| `CameraView.swift` | Camera/photo library picker |
| `ResultView.swift` | Classification result with animated reveal |
| `HistoryView.swift` | Scan history with eco-score |
| `ClassificationViewModel.swift` | State management + history persistence |
| `Extensions.swift` | Colors, image helpers, view modifiers |
| `Info.plist` | Camera/photo permissions |

---

## 🎨 Design System

- **Theme**: Dark mode eco-friendly
- **Primary**: `#33DE8F` (Eco Green)
- **Danger**: `#F55259` (Non-biodegradable red)
- **Warning**: `#FFC83D` (Unknown yellow)
- **Background**: `#0F141F` (Deep dark)
- **Cards**: Glassmorphism with `.ultraThinMaterial`
- **Animations**: Pulse, floating leaves, spring transitions

---

## 🧪 Sample Photos

4 sample photos are included in `SamplePhotos/` for testing:
1. `sample_plastic_bottle.png` — Should classify as **Non-Biodegradable**
2. `sample_banana_peel.png` — Should classify as **Biodegradable**
3. `sample_paper_waste.png` — Should classify as **Biodegradable**
4. `sample_metal_cans.png` — Should classify as **Non-Biodegradable**

Use these to test the app via Photo Library if you don't have trash items nearby!

---

## 📄 License

This project uses the [Apple FastViT-T8 model](https://huggingface.co/apple/coreml-FastViT-T8) which is available under Apple's license terms.

