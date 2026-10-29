//
//  ImageClassifier.swift
//  EcoLens
//
//  CoreML + Vision framework integration for FastViT-T8 image classification
//

import Foundation
import CoreML
import Vision
import UIKit

/// MARK: - Image Classifier
class ImageClassifier {

    private var model: VNCoreMLModel?

    // All model access happens on this queue, so loading the model never blocks app launch
    private let queue = DispatchQueue(label: "com.ecolens.classifier", qos: .userInitiated)

    // Predictions below this confidence are ignored
    private let minimumConfidence: Float = 0.10

    init() {
        queue.async { [weak self] in
            self?.loadModel()
        }
    }

    // MARK: - Load FastViT-T8 Model
    private func loadModel() {
        do {
            // Xcode auto-generates a class from the .mlpackage name
            // The model file is "FastViTT8F16.mlpackage"
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use GPU + Neural Engine for best performance

            let mlModel = try FastViTT8F16(configuration: config).model
            model = try VNCoreMLModel(for: mlModel)
            print("✅ FastViT-T8 model loaded successfully")
        } catch {
            print("❌ Failed to load FastViT-T8 model: \(error.localizedDescription)")

            // Fallback: try loading from bundle by name
            do {
                guard let modelURL = Bundle.main.url(forResource: "FastViTT8F16", withExtension: "mlmodelc") else {
                    print("❌ Model file not found in bundle")
                    return
                }
                let mlModel = try MLModel(contentsOf: modelURL)
                model = try VNCoreMLModel(for: mlModel)
                print("✅ FastViT-T8 model loaded from bundle fallback")
            } catch {
                print("❌ Fallback loading also failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Classify Image
    func classify(image: UIImage, completion: @escaping (Result<ClassificationResult, ClassificationError>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(.invalidImage))
            return
        }

        // Camera photos are usually stored rotated; tell Vision so the model sees them upright
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        // Queued behind loadModel(), so this runs once the model is ready
        queue.async { [weak self] in
            guard let self = self else { return }

            guard let model = self.model else {
                DispatchQueue.main.async {
                    completion(.failure(.modelNotLoaded))
                }
                return
            }

            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.classificationFailed(error.localizedDescription)))
                }
                return
            }

            guard let results = request.results as? [VNClassificationObservation], !results.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(.noResults))
                }
                return
            }

            let result = self.makeResult(from: results, image: image)
            DispatchQueue.main.async {
                completion(.success(result))
            }

            // Print top 5 results for debugging
            #if DEBUG
            print("\n🔍 Classification Results:")
            for (index, observation) in results.prefix(5).enumerated() {
                let name = TrashCategoryMapper.displayName(for: observation.identifier)
                print("  \(index + 1). \(name): \(String(format: "%.1f%%", observation.confidence * 100))")
            }
            #endif
        }
    }

    // MARK: - Build Result
    /// Uses the most confident of the top 5 predictions that maps to a known category,
    /// so a recognisable item isn't reported as unknown just because it wasn't ranked first
    private func makeResult(from observations: [VNClassificationObservation], image: UIImage) -> ClassificationResult {
        var chosen = observations[0]
        var category: TrashCategory = .unknown
        var decompositionTime = "Unable to estimate"

        for observation in observations.prefix(5) where observation.confidence >= minimumConfidence {
            let mapping = TrashCategoryMapper.categorize(label: observation.identifier)
            if mapping.category != .unknown {
                chosen = observation
                category = mapping.category
                decompositionTime = mapping.decompositionTime
                break
            }
        }

        // Store a small thumbnail rather than the full-resolution photo
        let imageData = image.thumbnail(maxDimension: 512).jpegData(compressionQuality: 0.6)

        return ClassificationResult(
            detectedLabel: TrashCategoryMapper.displayName(for: chosen.identifier).capitalized,
            confidence: Double(chosen.confidence),
            category: category,
            decompositionTime: decompositionTime,
            imageData: imageData
        )
    }
}

// MARK: - Orientation Conversion
extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

/ MARK: - Classification Errors
enum ClassificationError: LocalizedError {
    case modelNotLoaded
    case invalidImage
    case classificationFailed(String)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "The AI model could not be loaded. Please restart the app."
        case .invalidImage:
            return "The selected image could not be processed."
        case .classificationFailed(let message):
            return "Classification failed: \(message)"
        case .noResults:
            return "No classification results were returned."
        }
    }
}
