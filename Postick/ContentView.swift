//
//  ContentView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//


import SwiftUI

struct ContentView: View {
    @State private var modelName: String = "toy_biplane_idle"
    @State private var showPhotoPicker = false
    @State private var navigateToCollageView = false
    @State private var isCollageButtonTapped = false
    @State private var selectedImages: [UIImage] = []

    var body: some View {
        NavigationStack {
            ZStack {
                ARViewContainer(modelName: $modelName)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            isCollageButtonTapped = false
                            showPhotoPicker = true
                        }) {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                        }
                        .padding()

                        Spacer()

                        Button(action: {
                            isCollageButtonTapped = true
                            showPhotoPicker = true
                        }) {
                            Image("collage")
                                .resizable()
                                .frame(width: 40, height: 40)
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
                    }
                })
            }
        }
    }
}

