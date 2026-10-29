# Plan: Replace FastViT-T8 with a Custom Create ML Waste Classifier

**Goal:** Train a model that predicts the *waste type* (plastic, paper, metal…) directly, instead of guessing an ImageNet object and looking it up in a table.

**You need:** a Mac with Xcode 15+ (Create ML ships with it), ~2 GB free disk, about 2–3 hours total.

---

## Phase 1 — Get a dataset (≈30 min)

1. Download **"Garbage Classification (12 classes)"** from Kaggle (search for it at kaggle.com/datasets; ~15k images, free account needed).
   Its classes: `battery, biological, brown-glass, cardboard, clothes, green-glass, metal, paper, plastic, shoes, trash, white-glass`.
2. Merge the three glass folders into a single `glass` folder (same disposal rule, and fewer classes means higher accuracy).
3. Optional but recommended: add 20–50 of **your own phone photos** per class (real trash, real lighting). This helps a lot with real-world accuracy.
4. Arrange the folders like this; the folder name becomes the label:

```
WasteDataset/
├── Training/        (~80% of images)
│   ├── battery/
│   ├── biological/
│   ├── cardboard/
│   ├── clothes/
│   ├── glass/
│   ├── metal/
│   ├── paper/
│   ├── plastic/
│   ├── shoes/
│   └── trash/
└── Testing/         (~20%, same subfolders, images NOT in Training)
```

Quick split in Terminal, run from inside `WasteDataset` with all images in `Training/` first:

```bash
cd Training; for d in */; do mkdir -p "../Testing/$d"; ls "$d" | sort -R | head -n $(( $(ls "$d" | wc -l) / 5 )) | while read f; do mv "$d$f" "../Testing/$d"; done; done; cd ..
```

**Checklist:** every class has at least 100 training images; no class has more than about 5× the images of the smallest.

---

## Phase 2 — Train in Create ML (≈30 min)

1. Xcode → menu **Xcode › Open Developer Tool › Create ML**.
2. **New Document → Image Classification**, name it `EcoLensWasteClassifier`.
3. **Training Data:** drag in `WasteDataset/Training`. **Testing Data:** drag in `WasteDataset/Testing`. Leave Validation on *Automatic*.
4. **Parameters:**
   - Feature extractor: **Image Feature Print V2** (newest one offered)
   - Iterations: **25** (raise to 50 if accuracy is still climbing)
   - Augmentations: tick **Crop, Rotate, Flip, Exposure, Blur, Noise** (makes it robust to real phone photos)
5. Click **Train**. Expect 10–30 min on Apple Silicon.

## Phase 3 — Check quality (≈15 min)

- Target: **≥ 85% testing accuracy**.
- Open the **Evaluation** tab → look at the confusion table. Common mix-ups: `paper` ↔ `cardboard`, `plastic` ↔ `trash`. Fix by adding more varied photos to those classes and retraining.
- Use the **Preview** tab: drag in the app's `EcoLens/SamplePhotos/*.png` and a few of your own photos.
- Happy? **Output** tab → **Get** → save `EcoLensWasteClassifier.mlmodel`.

---

## Phase 4 — Plug it into the app (≈45 min)

1. Drag `EcoLensWasteClassifier.mlmodel` into the Xcode project (tick *Copy items if needed* and the EcoLens target). Xcode generates the `EcoLensWasteClassifier` class.
2. Remove `FastViTT8F16.mlpackage` from the project.
3. **`ImageClassifier.swift` → `loadModel()`:** swap the model class:

```swift
let mlModel = try EcoLensWasteClassifier(configuration: config).model
```

   and the bundle fallback's resource name to `"EcoLensWasteClassifier"`.

4. **`TrashCategories.swift`:** the labels are now waste types, so replace the 200-entry ImageNet tables with one small table:

```swift
static let wasteTypes: [String: Mapping] = [
    "biological": (.biodegradable,    "2 weeks - 6 months"),
    "paper":      (.biodegradable,    "2-6 weeks"),
    "cardboard":  (.biodegradable,    "2-3 months"),
    "clothes":    (.biodegradable,    "1-5 years (natural fibres) / 200+ years (synthetic)"),
    "plastic":    (.nonBiodegradable, "450+ years"),
    "metal":      (.nonBiodegradable, "50-500 years"),
    "glass":      (.nonBiodegradable, "1 million years"),
    "battery":    (.nonBiodegradable, "never (hazardous waste)"),
    "shoes":      (.nonBiodegradable, "25-80 years"),
    "trash":      (.nonBiodegradable, "varies"),
]

static func categorize(label: String) -> Mapping {
    wasteTypes[label.lowercased()] ?? (.unknown, "Unable to estimate")
}
```

5. **Better tips (recommended):** give each waste type its own disposal tip, e.g. *battery → "Take to a battery drop-off point, never in household bins"*, *glass → "Rinse and put in the glass recycling bin"*. Add a `disposalTip(for label:)` function next to the table and show it in `ResultView` instead of the generic per-category tip.
6. **`ImageClassifier.swift` → confidence:** with 10 classes, raise `minimumConfidence` from `0.10` to about **`0.40`**, so unsure guesses show "Unknown" instead of a wrong answer. Remove the "top 5" loop and just use the top result.
7. **README:** delete the FastViT download step and mention the new model.

> Tip: if you want, ask Claude to do steps 3–7 as code changes after you've added the model. Share the exact class labels it shows in Create ML.

---

## Phase 5 — Test (≈20 min)

| Test | Expected |
|---|---|
| `sample_plastic_bottle.png` | Plastic → Non-Biodegradable |
| `sample_banana_peel.png` | Biological → Biodegradable |
| `sample_paper_waste.png` | Paper → Biodegradable |
| `sample_metal_cans.png` | Metal → Non-Biodegradable |
| Photo of a random non-trash item (e.g. your hand) | Low confidence → Unknown |
| Real trash photos on a physical iPhone | Mostly correct; note failures and add similar photos to the dataset |

Run in the Simulator (photo library) and on a real iPhone (camera).

---

## Later improvements

- **Improvement loop:** collect photos the app gets wrong → add them to the dataset → retrain (Create ML can resume from the previous session).
- **Fallback:** when confidence is low, run Apple's built-in `VNClassifyImageRequest` to at least show what object it is.
- **More classes:** `e-waste`, `styrofoam`, `textile` if your area recycles them separately.
