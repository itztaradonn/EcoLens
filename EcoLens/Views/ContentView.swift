//
//  ContentView.swift
//  EcoLens
//
//  Main screen with animated hero section, scan button, and recent history
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ClassificationViewModel
    @State private var isPulsing = true
    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var selectedTab = 0
    @State private var leafOffset: [CGFloat] = Array(repeating: 0, count: 6)
    @State private var leafOpacity: [Double] = Array(repeating: 0.3, count: 6)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Home Tab
            NavigationView {
                ZStack {
                    // Background
                    Color.ecoBgPrimary.ignoresSafeArea()
                    
                    // Floating leaf particles
                    floatingLeaves
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            // Hero Section
                            heroSection
                            
                            // Stats Cards
                            if viewModel.totalScans > 0 {
                                statsSection
                            }
                            
                            // Scan Button
                            scanButton
                            
                            // Loading State
                            if viewModel.isClassifying {
                                classifyingView
                            }
                            
                            // Recent Scans
                            if !viewModel.scanHistory.isEmpty {
                                recentScansSection
                            }
                            
                            // Tips Section
                            tipsSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.ecoGreen)
                            Text("EcoLens")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .tabItem {
                Image(systemName: "camera.viewfinder")
                Text("Scan")
            }
            .tag(0)
            
            // MARK: - History Tab
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
                .tag(1)
        }
        .accentColor(.ecoGreen)
        .sheet(isPresented: $showSourcePicker) {
            ImageSourcePicker(
                isPresented: $showSourcePicker,
                selectedImage: $capturedImage,
                showCamera: $showCamera,
                showPhotoLibrary: $showPhotoLibrary
            )
            .environmentObject(viewModel)
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.ecoBgSecondary)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $capturedImage, isPresented: $showCamera, sourceType: .camera)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            CameraView(image: $capturedImage, isPresented: $showPhotoLibrary, sourceType: .photoLibrary)
        }
        .fullScreenCover(isPresented: $viewModel.showResult) {
            if let result = viewModel.currentResult {
                ResultView(result: result, image: viewModel.selectedImage)
                    .environmentObject(viewModel)
            }
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                viewModel.classifyImage(image)
                capturedImage = nil
            }
        }
        .onAppear {
            startLeafAnimations()
        }
        .alert("Classification Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.resetToIdle() }
            }
        )) {
            Button("OK") {
                viewModel.resetToIdle()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.ecoGreen.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isPulsing ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPulsing)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient.ecoGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: .ecoGreen.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "leaf.arrow.triangle.circlepath")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
            }
            .onAppear { isPulsing = true }
            
            Text("Scan Your Trash")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Take a photo to find out if it's\nbiodegradable or not")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "chart.bar.fill",
                value: "\(viewModel.totalScans)",
                label: "Total Scans",
                color: .ecoSky
            )
            
            StatCard(
                icon: "leaf.fill",
                value: "\(viewModel.biodegradableCount)",
                label: "Biodegradable",
                color: .ecoGreen
            )
            
            StatCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(viewModel.nonBiodegradableCount)",
                label: "Non-Bio",
                color: .ecoNonBiodegradable
            )
        }
    }
    
    // MARK: - Scan Button
    private var scanButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showSourcePicker = true
        }) {
            HStack(spacing: 14) {
                Image(systemName: "camera.viewfinder")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Scan Trash Now")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient.ecoGradient
                    .shadow(.inner(color: .white.opacity(0.2), radius: 4, x: 0, y: 2))
            )
            .cornerRadius(20)
            .shadow(color: .ecoGreen.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .pulseAnimation(isPulsing)
        .disabled(viewModel.isClassifying)
        .opacity(viewModel.isClassifying ? 0.6 : 1.0)
    }
    
    // MARK: - Classifying View
    private var classifyingView: some View {
        VStack(spacing: 20) {
            // Animated scanning indicator
            ZStack {
                Circle()
                    .stroke(Color.ecoBgCard, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient.ecoGradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isPulsing ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isPulsing)
                
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.title)
                    .foregroundColor(.ecoGreen)
            }
            
            Text("Analyzing with AI...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("FastViT-T8 is classifying your image")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .glassCard()
    }
    
    // MARK: - Recent Scans
    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Scans")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { selectedTab = 1 }) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.ecoGreen)
                }
            }
            
            ForEach(viewModel.scanHistory.prefix(3)) { result in
                RecentScanRow(result: result)
            }
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Eco Tips 💡")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TipCard(
                icon: "leaf.fill",
                title: "Compost Organic Waste",
                description: "Food scraps and yard waste can become nutrient-rich soil through composting.",
                color: .ecoGreen
            )
            
            TipCard(
                icon: "arrow.3.trianglepath",
                title: "Reduce, Reuse, Recycle",
                description: "Follow the 3 R's to minimize your environmental footprint.",
                color: .ecoSky
            )
            
            TipCard(
                icon: "drop.fill",
                title: "Avoid Single-Use Plastics",
                description: "Plastic takes 450+ years to decompose. Choose reusable alternatives.",
                color: .ecoSunset
            )
        }
    }
    
    // MARK: - Floating Leaves Animation
    private var floatingLeaves: some View {
        GeometryReader { geometry in
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: "leaf.fill")
                    .font(.system(size: CGFloat.random(in: 10...20)))
                    .foregroundColor(.ecoGreen.opacity(leafOpacity[index]))
                    .offset(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: leafOffset[index]
                    )
                    .rotationEffect(.degrees(Double(leafOffset[index]) * 0.5))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private func startLeafAnimations() {
        for index in 0..<6 {
            let delay = Double.random(in: 0...3)
            let duration = Double.random(in: 8...15)
            
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false).delay(delay)) {
                leafOffset[index] = UIScreen.main.bounds.height + 50
                leafOpacity[index] = 0
            }
        }
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }
}

struct RecentScanRow: View {
    let result: ClassificationResult
    
    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            if let imageData = result.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .cornerRadius(12)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ecoBgElevated)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.detectedLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(result.category.emoji)
                        .font(.caption)
                    Text(result.category.rawValue)
                        .font(.caption)
                        .foregroundColor(
                            result.category == .biodegradable ? .ecoGreen :
                            result.category == .nonBiodegradable ? .ecoNonBiodegradable :
                            .ecoUnknown
                        )
                }
            }
            
            Spacer()
            
            // Confidence
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(result.confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.ecoGreen)
                
                Text(result.date.timeAgoDisplay)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(Color.ecoBgCard)
        .cornerRadius(16)
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.ecoBgCard)
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ClassificationViewModel())
}
