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

// MARK: - Image Classifier
class ImageClassifier {
    
    private var model: VNCoreMLModel?
    
    init() {
        loadModel()
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
        guard let model = model else {
            completion(.failure(.modelNotLoaded))
            return
        }
        
        guard let cgImage = image.cgImage else {
            completion(.failure(.invalidImage))
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.classificationFailed(error.localizedDescription)))
                }
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                DispatchQueue.main.async {
                    completion(.failure(.noResults))
                }
                return
            }
            
            // Get top result
            let label = topResult.identifier
            let confidence = Double(topResult.confidence)
            
            // Map to trash category
            let (category, decompositionTime) = TrashCategoryMapper.categorize(label: label)
            
            // If confidence is too low, mark as unknown
            let finalCategory = confidence < 0.10 ? .unknown : category
            let finalDecomposition = confidence < 0.10 ? "Unable to estimate" : decompositionTime
            
            // Create compressed image data for storage
            let imageData = image.jpegData(compressionQuality: 0.3)
            
            let displayLabel = TrashCategoryMapper.displayName(for: label)
            
            let result = ClassificationResult(
                detectedLabel: displayLabel.capitalized,
                confidence: confidence,
                category: finalCategory,
                decompositionTime: finalDecomposition,
                imageData: imageData
            )
            
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
        
        // Configure the request
        request.imageCropAndScaleOption = .centerCrop
        
        // Perform the request
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.classificationFailed(error.localizedDescription)))
                }
            }
        }
    }
}

// MARK: - Classification Errors
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
