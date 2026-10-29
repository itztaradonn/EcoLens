//
//  Extensions.swift
//  EcoLens
//

import SwiftUI
import UIKit

// MARK: - Color Palette (Eco Theme)
extension Color {
    // Primary greens
    static let ecoGreen = Color(red: 0.2, green: 0.87, blue: 0.56)
    static let ecoGreenDark = Color(red: 0.13, green: 0.68, blue: 0.44)
    static let ecoGreenLight = Color(red: 0.4, green: 0.95, blue: 0.68)
    
    // Accent colors
    static let ecoLeaf = Color(red: 0.18, green: 0.75, blue: 0.42)
    static let ecoEarth = Color(red: 0.55, green: 0.38, blue: 0.24)
    static let ecoSky = Color(red: 0.25, green: 0.72, blue: 0.92)
    static let ecoSunset = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    // Status colors
    static let ecoBiodegradable = Color(red: 0.2, green: 0.87, blue: 0.56)
    static let ecoNonBiodegradable = Color(red: 0.96, green: 0.32, blue: 0.35)
    static let ecoUnknown = Color(red: 1.0, green: 0.78, blue: 0.24)
    
    // Background
    static let ecoBgPrimary = Color(red: 0.06, green: 0.08, blue: 0.12)
    static let ecoBgSecondary = Color(red: 0.1, green: 0.12, blue: 0.18)
    static let ecoBgCard = Color(red: 0.12, green: 0.15, blue: 0.22)
    static let ecoBgElevated = Color(red: 0.16, green: 0.19, blue: 0.26)
}

// MARK: - UIImage Extensions
extension UIImage {
    /// Resize image to target size maintaining aspect ratio
    func resized(to targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
    
    /// Downscale so the longest side is at most `maxDimension` pixels (never upscales)
    func thumbnail(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width * scale, size.height * scale)
        guard longestSide > maxDimension else { return self }

        let scaleFactor = maxDimension / longestSide
        let targetSize = CGSize(
            width: size.width * scale * scaleFactor,
            height: size.height * scale * scaleFactor
        )

        // Render at 1x so the size is in pixels, not points
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Center-crop and resize image to exact square size (for model input)
    func centerCroppedAndResized(to dimension: CGFloat) -> UIImage {
        let shortSide = min(size.width, size.height)
        let cropRect = CGRect(
            x: (size.width - shortSide) / 2,
            y: (size.height - shortSide) / 2,
            width: shortSide,
            height: shortSide
        )
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else { return self }
        let croppedImage = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        
        let targetSize = CGSize(width: dimension, height: dimension)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

// MARK: - Date Formatting
extension Date {
    // Formatters are expensive to create, so share them instead of building one per list row
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var timeAgoDisplay: String {
        Date.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }

    var formattedDisplay: String {
        Date.displayFormatter.string(from: self)
    }
}

// MARK: - View Extensions
extension View {
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(Color.ecoBgCard.opacity(0.6))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    func pulseAnimation(_ isAnimating: Bool) -> some View {
        self.scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                isAnimating ?
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true) :
                    .default,
                value: isAnimating
            )
    }
}

// MARK: - Gradient Helpers
extension LinearGradient {
    static let ecoGradient = LinearGradient(
        colors: [.ecoGreen, .ecoSky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let ecoDarkGradient = LinearGradient(
        colors: [.ecoBgPrimary, .ecoBgSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let biodegradableGradient = LinearGradient(
        colors: [Color.ecoGreen, Color.ecoLeaf],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let nonBiodegradableGradient = LinearGradient(
        colors: [Color.ecoNonBiodegradable, Color(red: 0.8, green: 0.2, blue: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
