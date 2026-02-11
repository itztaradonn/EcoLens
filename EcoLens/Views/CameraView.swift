//
//  CameraView.swift
//  EcoLens
//
//  UIImagePickerController wrapper for camera and photo library access
//

import SwiftUI
import UIKit

// MARK: - Camera View (UIImagePickerController Wrapper)
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        // Style the picker
        picker.navigationBar.tintColor = UIColor(Color.ecoGreen)
        
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraFlashMode = .auto
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Source Selection Sheet
struct ImageSourcePicker: View {
    @EnvironmentObject var viewModel: ClassificationViewModel
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var showCamera: Bool
    @Binding var showPhotoLibrary: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)
            
            Text("Choose Source")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 24)
            
            // Camera button
            Button(action: {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCamera = true
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.ecoGradient)
                            .frame(width: 56, height: 56)
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Take Photo")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Use camera to scan trash")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.ecoBgCard)
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Photo Library button
            Button(action: {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPhotoLibrary = true
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.ecoSky, .ecoGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photo Library")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Choose from your photos")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.ecoBgCard)
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.ecoBgSecondary)
    }
}
