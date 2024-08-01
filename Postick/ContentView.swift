//
//  ContentView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var navigateToCollageView = false
    @State private var isCollageButtonTapped = false
    @State private var isPhotoButtonTapped = false
    @State private var selectedImages: [UIImage] = []
    @State private var capturedImage: UIImage?
    @State private var showBlackScreen = false

    var body: some View {
        NavigationStack {
            ZStack {
                ARViewContainer(selectedImage: $selectedImage, onPhotoCaptured: { image in
                    capturedImage = image
                    // Handle the captured image as needed
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil) // Save to photo library
                    withAnimation {
                        showBlackScreen = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            showBlackScreen = false
                        }
                    }
                })
                .edgesIgnoringSafeArea(.all)

                if showBlackScreen {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                }

                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            isCollageButtonTapped = false
                            isPhotoButtonTapped = true
                            showPhotoPicker = true
                        }) {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black)
                        }
                        .padding()

                        Spacer()

                        Button(action: {
                            // Trigger photo capture
                            NotificationCenter.default.post(name: Notification.Name("capturePhoto"), object: nil)
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .shadow(radius: 2)
                        }
                        .padding()

                        Spacer()

                        Button(action: {
                            isCollageButtonTapped = true
                            isPhotoButtonTapped = false
                            showPhotoPicker = true
                        }) {
                            Image("collage")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                }

                NavigationLink(destination: CollageView(images: selectedImages), isActive: $navigateToCollageView) {
                    EmptyView()
                }
            }
            .navigationTitle("AR View")
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(onPhotosSelected: { images in
                    showPhotoPicker = false
                    if isCollageButtonTapped {
                        selectedImages = images
                        if selectedImages.count == 2 {
                            navigateToCollageView = true
                        }
                    } else if isPhotoButtonTapped {
                        selectedImage = images.first
                        isPhotoButtonTapped = false // Reset the flag
                    }
                }, selectionLimit: isCollageButtonTapped ? 2 : 1)
            }
        }
    }
}
