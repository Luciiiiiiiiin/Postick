//
//  CollageView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/24.
//  This file display the collage view when user decides to go to the collage mode in the app

import SwiftUI

struct CollageView: View {
    let images: [UIImage] // An array of images to be used in the collage
    @State private var selectedTemplate: TemplateType = .vertical // State variable to track the selected template type
    @State private var showAlert = false // State variable to control the display of the success alert

    // Enum representing the different template types
    enum TemplateType: String, CaseIterable, Identifiable {
        case vertical = "Vertical"
        case horizontal = "Horizontal"

        // Identifier for each case, required by Identifiable protocol
        var id: String { self.rawValue }

        // Property to return the appropriate template based on the selected type
        var template: Template {
            switch self {
            case .vertical:
                return VerticalTemplate()
            case .horizontal:
                return HorizontalTemplate()
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Picker to select between vertical and horizontal templates
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(TemplateType.allCases) { template in
                        Text(template.rawValue).tag(template)
                    }
                }
                .pickerStyle(SegmentedPickerStyle()) // Use segmented control style
                .padding()

                // Display the images based on the selected template
                if images.count == 2 {
                    if selectedTemplate == .vertical {
                        VStack(spacing: 0) {
                            Image(uiImage: images[0])
                                .resizable()
                                .scaledToFit()
                            Image(uiImage: images[1])
                                .resizable()
                                .scaledToFit()
                        }
                    } else if selectedTemplate == .horizontal {
                        HStack(spacing: 0) {
                            Image(uiImage: images[0])
                                .resizable()
                                .scaledToFit()
                            Image(uiImage: images[1])
                                .resizable()
                                .scaledToFit()
                        }
                    }
                } else {
                    // Display a message if less than two images are selected
                    Text("Please select two images.")
                        .padding()
                }

                // Button to save the collage if two images are selected
                if images.count == 2 {
                    Button(action: {
                        // Generate the collage using the selected template
                        if let collagedImage = selectedTemplate.template.generateCollage(images: images) {
                            // Save the collaged image to the photo library
                            UIImageWriteToSavedPhotosAlbum(collagedImage, nil, nil, nil)
                            // Show success alert
                            showAlert = true
                        }
                    }) {
                        Text("Save Collage")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Success"), message: Text("The collage has been saved to your photo library."), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .navigationTitle("Collage")
        }
    }
}
