//
//  ClassificationViewModel.swift
//  EcoLens
//
//  State management for image classification flow
//

import Foundation
import SwiftUI
import UIKit

// MARK: - App State
enum AppState: Equatable {
    case idle
    case capturing
    case classifying
    case result
    case error(String)
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.capturing, .capturing),
             (.classifying, .classifying), (.result, .result):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - ViewModel
class ClassificationViewModel: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var selectedImage: UIImage?
    @Published var currentResult: ClassificationResult?
    @Published var scanHistory: [ClassificationResult] = []
    @Published var showCamera = false
    @Published var showPhotoLibrary = false
    @Published var showResult = false
    @Published var isClassifying = false
    @Published var errorMessage: String?
    
    private let classifier = ImageClassifier()
    // Legacy UserDefaults key, read once to migrate older history
    private let historyKey = "eco_lens_scan_history"
    // Serial so saves are written in order
    private let storageQueue = DispatchQueue(label: "com.ecolens.history", qos: .utility)
    private let historyFileURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("scan_history.json")

    init() {
        loadHistory()
    }

    // MARK: - Classification
    func classifyImage(_ image: UIImage) {
        // Ignore new photos while one is still being classified
        guard !isClassifying else { return }

        selectedImage = image
        appState = .classifying
        isClassifying = true
        errorMessage = nil
        
        // Add a slight delay for the loading animation to feel natural
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.classifier.classify(image: image) { [weak self] result in
                guard let self = self else { return }
                
                self.isClassifying = false
                
                switch result {
                case .success(let classificationResult):
                    self.currentResult = classificationResult
                    self.appState = .result
                    self.showResult = true
                    
                    // Add to history
                    self.scanHistory.insert(classificationResult, at: 0)
                    
                    // Keep only last 50 items
                    if self.scanHistory.count > 50 {
                        self.scanHistory = Array(self.scanHistory.prefix(50))
                    }
                    
                    self.saveHistory()
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.appState = .error(error.localizedDescription)
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
    
    // MARK: - Reset
    func resetToIdle() {
        appState = .idle
        selectedImage = nil
        currentResult = nil
        showResult = false
        isClassifying = false
        errorMessage = nil
    }
    
    // MARK: - History Management
    func deleteHistoryItem(at offsets: IndexSet) {
        scanHistory.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func clearHistory() {
        scanHistory.removeAll()
        saveHistory()
    }
    
    // History holds image data, which is too large for UserDefaults, so it lives in a file
    private func saveHistory() {
        let history = scanHistory
        let url = historyFileURL
        storageQueue.async {
            do {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let data = try JSONEncoder().encode(history)
                try data.write(to: url, options: .atomic)
            } catch {
                print("❌ Failed to save history: \(error)")
            }
        }
    }

    private func loadHistory() {
        let legacyData = UserDefaults.standard.data(forKey: historyKey)
        guard let data = (try? Data(contentsOf: historyFileURL)) ?? legacyData else { return }
        do {
            scanHistory = try JSONDecoder().decode([ClassificationResult].self, from: data)

            // Move history saved by older versions out of UserDefaults
            if legacyData != nil {
                saveHistory()
                UserDefaults.standard.removeObject(forKey: historyKey)
            }
        } catch {
            print("❌ Failed to load history: \(error)")
        }
    }
    
    // MARK: - Stats
    var totalScans: Int { scanHistory.count }
    
    var biodegradableCount: Int {
        scanHistory.filter { $0.category == .biodegradable }.count
    }
    
    var nonBiodegradableCount: Int {
        scanHistory.filter { $0.category == .nonBiodegradable }.count
    }
    
    var biodegradablePercentage: Double {
        guard totalScans > 0 else { return 0 }
        return Double(biodegradableCount) / Double(totalScans) * 100
    }
}
