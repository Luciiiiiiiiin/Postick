//
//  CollageView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/24.
//

import SwiftUI

struct CollageView: View {
    let images: [UIImage]
    @State private var selectedTemplate: TemplateType = .vertical
    @State private var showAlert = false

    enum TemplateType: String, CaseIterable, Identifiable {
        case vertical = "Vertical"
        case horizontal = "Horizontal"

        var id: String { self.rawValue }

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
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(TemplateType.allCases) { template in
                        Text(template.rawValue).tag(template)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

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
                    Text("Please select two images.")
                        .padding()
                }

                if images.count == 2 {
                    Button(action: {
                        if let collagedImage = selectedTemplate.template.generateCollage(images: images) {
                            UIImageWriteToSavedPhotosAlbum(collagedImage, nil, nil, nil)
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
