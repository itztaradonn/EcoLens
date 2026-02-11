//
//  ResultView.swift
//  EcoLens
//
//  Classification result display with animated reveal and detailed info
//

import SwiftUI

struct ResultView: View {
    let result: ClassificationResult
    let image: UIImage?
    @EnvironmentObject var viewModel: ClassificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showContent = false
    @State private var progressValue: CGFloat = 0
    @State private var showDetails = false
    @State private var cardScale: CGFloat = 0.8
    
    private var categoryColor: Color {
        switch result.category {
        case .biodegradable: return .ecoGreen
        case .nonBiodegradable: return .ecoNonBiodegradable
        case .unknown: return .ecoUnknown
        }
    }
    
    private var categoryGradient: LinearGradient {
        switch result.category {
        case .biodegradable: return .biodegradableGradient
        case .nonBiodegradable: return .nonBiodegradableGradient
        case .unknown: return LinearGradient(colors: [.ecoUnknown, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.ecoBgPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                            viewModel.resetToIdle()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Image Preview
                    imageSection
                    
                    // Result Card
                    resultCard
                        .scaleEffect(cardScale)
                        .opacity(showContent ? 1 : 0)
                    
                    // Details Section
                    if showDetails {
                        detailsSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Action Buttons
                    actionButtons
                        .opacity(showContent ? 1 : 0)
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                showContent = true
                cardScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.6)) {
                progressValue = CGFloat(result.confidence)
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                showDetails = true
            }
        }
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(24)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(categoryColor.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: categoryColor.opacity(0.3), radius: 20, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.ecoBgCard)
                    .frame(height: 280)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.3))
                    )
            }
            
            // Category badge
            HStack(spacing: 6) {
                Text(result.category.emoji)
                Text(result.category.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(categoryColor)
            .cornerRadius(20)
            .padding(16)
        }
    }
    
    // MARK: - Result Card
    private var resultCard: some View {
        VStack(spacing: 20) {
            // Detected item
            VStack(spacing: 8) {
                Text("Detected Item")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .tracking(1.5)
                
                Text(result.detectedLabel)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            // Confidence circle
            ZStack {
                Circle()
                    .stroke(Color.ecoBgElevated, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        categoryGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(result.confidence * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(categoryColor)
                    
                    Text("confidence")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Category description
            Text(result.category.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.ecoBgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: categoryColor.opacity(0.15), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(spacing: 14) {
            // Decomposition Time
            DetailRow(
                icon: "clock.fill",
                label: "Decomposition Time",
                value: result.decompositionTime,
                color: categoryColor
            )
            
            // Disposal Tip
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.ecoSunset)
                    Text("Disposal Tip")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text(result.category.disposalTip)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.ecoBgCard)
            .cornerRadius(16)
            
            // Environmental Impact
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "globe.americas.fill")
                        .foregroundColor(.ecoSky)
                    Text("Environmental Impact")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text(environmentalImpactText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.ecoBgCard)
            .cornerRadius(16)
        }
    }
    
    private var environmentalImpactText: String {
        switch result.category {
        case .biodegradable:
            return "✅ Low impact — This item will naturally decompose and return nutrients to the soil. Composting is the best option to minimize methane emissions from landfills."
        case .nonBiodegradable:
            return "🔴 High impact — This item persists in the environment and can harm wildlife, contaminate water, and contribute to microplastic pollution. Always recycle when possible."
        case .unknown:
            return "⚠️ Impact uncertain — Please check your local waste management guidelines for proper classification and disposal of this item."
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                dismiss()
                viewModel.resetToIdle()
                // Slight delay before showing camera again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.showCamera = true
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Scan Another Item")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(LinearGradient.ecoGradient)
                .cornerRadius(16)
            }
            
            Button(action: {
                dismiss()
                viewModel.resetToIdle()
            }) {
                Text("Back to Home")
                    .font(.headline)
                    .foregroundColor(.ecoGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.ecoBgCard)
                    .cornerRadius(16)
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(18)
        .background(Color.ecoBgCard)
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    ResultView(
        result: ClassificationResult(
            detectedLabel: "Water Bottle",
            confidence: 0.89,
            category: .nonBiodegradable,
            decompositionTime: "450 years"
        ),
        image: nil
    )
    .environmentObject(ClassificationViewModel())
}
