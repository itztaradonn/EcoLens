//
//  TrashCategories.swift
//  EcoLens
//
//  Maps ImageNet-1k labels from FastViT-T8 to biodegradable/non-biodegradable categories
//

import Foundation

// MARK: - Trash Category Enum
enum TrashCategory: String, Codable {
    case biodegradable = "Biodegradable"
    case nonBiodegradable = "Non-Biodegradable"
    case unknown = "Unknown"
    
    var emoji: String {
        switch self {
        case .biodegradable: return "🌱"
        case .nonBiodegradable: return "⚠️"
        case .unknown: return "❓"
        }
    }
    
    var description: String {
        switch self {
        case .biodegradable:
            return "This item can naturally decompose and break down into organic matter through biological processes."
        case .nonBiodegradable:
            return "This item cannot naturally decompose and will persist in the environment for a very long time."
        case .unknown:
            return "Unable to determine the biodegradability of this item. Please consult local waste management guidelines."
        }
    }
    
    var disposalTip: String {
        switch self {
        case .biodegradable:
            return "♻️ Compost it! Place in your organic waste bin or home compost. It will naturally break down and enrich the soil."
        case .nonBiodegradable:
            return "🗑️ Check if this item can be recycled. If not, dispose of it in the general waste bin. Never litter!"
        case .unknown:
            return "🔍 Check with your local waste management facility for proper disposal instructions."
        }
    }
}

// MARK: - Classification Result
struct ClassificationResult: Identifiable, Codable {
    let id: UUID
    let detectedLabel: String
    let confidence: Double
    let category: TrashCategory
    let decompositionTime: String
    let date: Date
    var imageData: Data?
    
    init(detectedLabel: String, confidence: Double, category: TrashCategory, decompositionTime: String, imageData: Data? = nil) {
        self.id = UUID()
        self.detectedLabel = detectedLabel
        self.confidence = confidence
        self.category = category
        self.decompositionTime = decompositionTime
        self.date = Date()
        self.imageData = imageData
    }
}

// MARK: - ImageNet Label to Trash Category Mapping
struct TrashCategoryMapper {
    
    typealias Mapping = (category: TrashCategory, decompositionTime: String)

    /// Maps an ImageNet label to a TrashCategory with decomposition info
    static func categorize(label: String) -> Mapping {
        // ImageNet labels may use underscores and list comma-separated synonyms,
        // e.g. "cellular_telephone, cellular_phone, cellphone"
        let synonyms = label
            .replacingOccurrences(of: "_", with: " ")
            .lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Exact match on any synonym
        for synonym in synonyms {
            if let mapping = lookup[synonym] {
                return mapping
            }
        }

        // Whole-word match, longest key first so "water bottle" beats "bottle"
        // and short keys like "ear" don't match inside "bearskin"
        for synonym in synonyms {
            let padded = " \(synonym) "
            for entry in entriesByLength where padded.contains(" \(entry.key) ") {
                return entry.value
            }
        }

        return (.unknown, "Unable to estimate")
    }

    /// Every mapping keyed by lowercased label
    private static let lookup: [String: Mapping] = {
        var table: [String: Mapping] = [:]
        for (key, time) in nonBiodegradableItems {
            table[key.lowercased()] = (.nonBiodegradable, time)
        }
        for (key, time) in biodegradableItems {
            table[key.lowercased()] = (.biodegradable, time)
        }
        return table
    }()

    /// Lookup entries sorted longest key first (then alphabetically) for deterministic partial matching
    private static let entriesByLength: [(key: String, value: Mapping)] = lookup.sorted {
        $0.key.count != $1.key.count ? $0.key.count > $1.key.count : $0.key < $1.key
    }

    // MARK: - Biodegradable Items (ImageNet labels)
    static let biodegradableItems: [String: String] = [
        // Fruits
        "banana": "2-5 weeks",
        "orange": "6 months",
        "lemon": "1-2 years",
        "fig": "1-2 weeks",
        "pineapple": "2-5 weeks",
        "jackfruit": "3-6 weeks",
        "custard apple": "2-4 weeks",
        "pomegranate": "3-6 weeks",
        "strawberry": "1-2 weeks",
        "apple": "1-2 months",
        "granny smith": "1-2 months",
        
        // Vegetables & Plants
        "mushroom": "1-2 weeks",
        "agaric": "1-2 weeks",
        "ear": "2-4 weeks",       // corn ear
        "corn": "2-4 weeks",
        "head cabbage": "1-3 weeks",
        "broccoli": "1-3 weeks",
        "cauliflower": "1-3 weeks",
        "zucchini": "1-3 weeks",
        "cucumber": "1-3 weeks",
        "artichoke": "2-4 weeks",
        "bell pepper": "2-4 weeks",
        "cardoon": "2-4 weeks",
        "spaghetti squash": "3-6 weeks",
        "acorn squash": "3-6 weeks",
        "butternut squash": "3-6 weeks",
        
        // Food items
        "meat loaf": "1-2 weeks",
        "pizza": "1-3 weeks",
        "burrito": "1-3 weeks",
        "bagel": "1-3 weeks",
        "pretzel": "2-4 weeks",
        "french loaf": "2-4 weeks",
        "dough": "1-2 weeks",
        "ice cream": "1-2 days",
        "chocolate sauce": "1-2 weeks",
        "guacamole": "1 week",
        "trifle": "1-2 weeks",
        "potpie": "2-4 weeks",
        "consomme": "1-2 days",
        "hotdog": "1-3 weeks",
        "cheeseburger": "1-3 weeks",
        "carbonara": "1-2 weeks",
        
        // Paper & Cardboard
        "newspaper": "2-6 weeks",
        "paper towel": "2-4 weeks",
        "cardboard": "2-3 months",
        "carton": "3 months",
        "envelope": "1-3 months",
        "comic book": "2-6 weeks",
        "book jacket": "2-6 weeks",
        "menu": "2-6 weeks",
        "toilet tissue": "2-4 weeks",
        "paper": "2-6 weeks",
        
        // Natural materials
        "hay": "1-3 months",
        "straw": "1-3 months",
        "wool": "1-5 years",
        "cotton": "1-5 months",
        "timber": "10-15 years",
        "log": "10-15 years",
        "wood": "10-15 years",
        "basket": "1-2 years",
        "wicker basket": "1-2 years",
        "hamper": "1-2 years",
        "cork": "1-3 years",
        "wooden spoon": "3-5 years",
        
        // Animals & Natural
        "leaf": "1-3 months",
        "flower": "1-2 weeks",
        "daisy": "1-2 weeks",
        "rose": "1-2 weeks",
        "sunflower": "2-4 weeks",
        "bouquet": "1-3 weeks",
        "feather boa": "several months",
        "eggnog": "1-2 days",
        "egg": "3-4 weeks",
        "honeycomb": "1-2 years",
        "beeswax": "1-2 years",
        
        // Fabric (natural fibers)
        "jean": "10-12 months",
        "jersey": "6 months - 1 year",
        "sock": "1-2 years (if cotton)",
        "sandal": "varies by material",
    ]
    
    // MARK: - Non-Biodegradable Items (ImageNet labels)
    static let nonBiodegradableItems: [String: String] = [
        // Plastic items
        "water bottle": "450 years",
        "plastic bag": "500-1000 years",
        "pop bottle": "450 years",
        "bottle": "450 years",
        "bottlecap": "450 years",
        "pill bottle": "450 years",
        "bucket": "300+ years",
        "pail": "300+ years",
        "milk can": "200+ years",
        "rain barrel": "300+ years",
        "crate": "300+ years (if plastic)",
        "shopping basket": "300+ years (if plastic)",
        "ladle": "never (if metal/plastic)",
        "spatula": "never (if plastic)",
        
        // Electronics
        "laptop": "never (e-waste)",
        "notebook": "never (if electronic)",
        "desktop computer": "never (e-waste)",
        "monitor": "never (e-waste)",
        "screen": "never (e-waste)",
        "television": "never (e-waste)",
        "cellphone": "never (e-waste)",
        "cell phone": "never (e-waste)",
        "cellular telephone": "never (e-waste)",
        "smartphone": "never (e-waste)",
        "iPod": "never (e-waste)",
        "mouse": "never (e-waste)",
        "keyboard": "never (e-waste)",
        "remote control": "never (e-waste)",
        "joystick": "never (e-waste)",
        "printer": "never (e-waste)",
        "modem": "never (e-waste)",
        "hard disc": "never (e-waste)",
        "loudspeaker": "never (e-waste)",
        "microphone": "never (e-waste)",
        "headphone": "never (e-waste)",
        "CD player": "never (e-waste)",
        "tape player": "never (e-waste)",
        "digital watch": "never (e-waste)",
        "digital clock": "never (e-waste)",
        "calculator": "never (e-waste)",
        
        // Metal items
        "can opener": "100+ years",
        "corkscrew": "100+ years",
        "beer bottle": "1 million years (glass)",
        "wine bottle": "1 million years (glass)",
        "beer glass": "1 million years",
        "goblet": "1 million years (glass)",
        "coffeepot": "100+ years",
        "teapot": "100+ years",
        "frying pan": "100+ years",
        "wok": "100+ years",
        "caldron": "100+ years",
        "Dutch oven": "100+ years",
        "soup bowl": "100+ years (if ceramic)",
        "mixing bowl": "100+ years",
        "plate": "100+ years (if ceramic)",
        "cup": "100+ years (if ceramic)",
        "mug": "100+ years (if ceramic)",
        "pan": "100+ years",
        "pot": "100+ years",
        "skillet": "100+ years",
        "fork": "100+ years",
        "knife": "100+ years",
        "spoon": "100+ years",
        "nail": "40-100 years",
        "screw": "40-100 years",
        "chain": "100+ years",
        "hook": "100+ years",
        "padlock": "100+ years",
        "safe": "100+ years",
        "tin can": "50-100 years",
        "pop can": "200 years",
        "aluminum": "200-500 years",
        "file": "100+ years",
        "hammer": "100+ years",
        "screwdriver": "100+ years",
        "wrench": "100+ years",
        "plunger": "100+ years",
        "hatchet": "100+ years",
        "cleaver": "100+ years",
        "letter opener": "100+ years",
        "safety pin": "100+ years",
        "paper clip": "100+ years",
        "magnetic compass": "100+ years",
        
        // Glass
        "sunglasses": "1 million years",
        "sunglass": "1 million years",
        "eyeglasses": "1 million years",
        "lens": "1 million years",
        "binoculars": "never",
        "hourglass": "1 million years",
        "window": "1 million years",
        "mirror": "1 million years",
        "vase": "1 million years (if glass)",
        
        // Clothing (synthetic)
        "running shoe": "200+ years",
        "sneaker": "200+ years",
        "Loafer": "40-50 years",
        "boot": "40-50 years",
        "cowboy boot": "40-50 years",
        "clog": "varies",
        "diaper": "450 years",
        "nappy": "450 years",
        
        // Rubber & Synthetic
        "tire": "2000 years",
        "rubber eraser": "500+ years",
        "balloon": "6 months - 4 years",
        
        // Vehicles & Large Items
        "car wheel": "2000 years",
        "wheel": "varies",
        "shopping cart": "100+ years",
        "barbell": "100+ years",
        "dumbbell": "100+ years",
        "gas pump": "never",
        "parking meter": "never",
        
        // Household non-biodegradable
        "refrigerator": "never",
        "washer": "never",
        "iron": "100+ years",
        "toaster": "never (e-waste)",
        "microwave": "never (e-waste)",
        "vacuum": "never",
        "electric fan": "never",
        "space heater": "never",
        "stove": "never",
        "sewing machine": "never",
        
        // Batteries & Hazardous
        "battery": "100 years (toxic)",
        "lighter": "100+ years",
        "matchstick": "6 months (but hazardous)",
        
        // Bags & Containers
        "backpack": "300+ years (if synthetic)",
        "suitcase": "100+ years",
        "briefcase": "100+ years",
        "trash can": "100+ years",
        "garbage": "varies",
        "ashcan": "100+ years",
        "wastebasket": "varies",
        
        // Styrofoam
        "Styrofoam": "500+ years",
        "foam": "500+ years",
        "cup (disposable)": "450 years",
    ]
    
    /// Get a human-readable display name from an ImageNet label
    static func displayName(for label: String) -> String {
        label
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: ",")
            .first
            .map(String.init) ?? label
    }
}
