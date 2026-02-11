//
//  HistoryView.swift
//  EcoLens
//
//  Scan history list with filtering and statistics
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: ClassificationViewModel
    @State private var selectedFilter: HistoryFilter = .all
    @State private var showClearAlert = false
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case biodegradable = "🌱 Bio"
        case nonBiodegradable = "⚠️ Non-Bio"
        case unknown = "❓ Unknown"
    }
    
    private var filteredHistory: [ClassificationResult] {
        switch selectedFilter {
        case .all: return viewModel.scanHistory
        case .biodegradable: return viewModel.scanHistory.filter { $0.category == .biodegradable }
        case .nonBiodegradable: return viewModel.scanHistory.filter { $0.category == .nonBiodegradable }
        case .unknown: return viewModel.scanHistory.filter { $0.category == .unknown }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.ecoBgPrimary.ignoresSafeArea()
                
                if viewModel.scanHistory.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Stats header
                        statsHeader
                        
                        // Filter chips
                        filterChips
                        
                        // History list
                        historyList
                    }
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.scanHistory.isEmpty {
                        Button(action: { showClearAlert = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.ecoNonBiodegradable)
                        }
                    }
                }
            }
            .alert("Clear History", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        viewModel.clearHistory()
                    }
                }
            } message: {
                Text("This will permanently delete all scan history. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.ecoBgCard)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            Text("No Scans Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Start scanning trash items to build\nyour environmental history")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Stats Header
    private var statsHeader: some View {
        VStack(spacing: 14) {
            // Eco Score
            HStack(spacing: 20) {
                // Biodegradable percentage ring
                ZStack {
                    Circle()
                        .stroke(Color.ecoBgElevated, lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.biodegradablePercentage / 100))
                        .stroke(
                            LinearGradient.biodegradableGradient,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(viewModel.biodegradablePercentage))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.ecoGreen)
                        Text("eco")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Eco Score")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.biodegradableCount) of \(viewModel.totalScans) items are biodegradable")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Mini progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.ecoBgElevated)
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.biodegradableGradient)
                                .frame(width: geometry.size.width * CGFloat(viewModel.biodegradablePercentage / 100), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(18)
        .background(Color.ecoBgCard)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HistoryFilter.allCases, id: \.rawValue) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == filter ? .bold : .medium)
                            .foregroundColor(selectedFilter == filter ? .white : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedFilter == filter ?
                                    AnyShapeStyle(LinearGradient.ecoGradient) :
                                    AnyShapeStyle(Color.ecoBgCard)
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
    
    // MARK: - History List
    private var historyList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(filteredHistory) { result in
                    HistoryRow(result: result)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - History Row
struct HistoryRow: View {
    let result: ClassificationResult
    
    private var categoryColor: Color {
        switch result.category {
        case .biodegradable: return .ecoGreen
        case .nonBiodegradable: return .ecoNonBiodegradable
        case .unknown: return .ecoUnknown
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            if let imageData = result.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .cornerRadius(14)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.ecoBgElevated)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(result.detectedLabel)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Category tag
                    HStack(spacing: 4) {
                        Text(result.category.emoji)
                            .font(.caption2)
                        Text(result.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(categoryColor.opacity(0.12))
                    .cornerRadius(8)
                    
                    // Decomposition time
                    Text("⏱ \(result.decompositionTime)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Text(result.date.formattedDisplay)
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
            
            // Confidence
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.ecoBgElevated, lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(result.confidence))
                        .stroke(categoryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(result.confidence * 100))")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(categoryColor)
                }
            }
        }
        .padding(14)
        .background(Color.ecoBgCard)
        .cornerRadius(18)
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(ClassificationViewModel())
}
