//
//  CollageView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/24.
//

import SwiftUI

struct CollageView: View {
    let images: [UIImage]
    @State private var showAlert = false

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                if images.count == 2 {
                    Image(uiImage: images[0])
                        .resizable()
                        .scaledToFit()
                    Image(uiImage: images[1])
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("Please select two images.")
                        .padding()
                }
            }
            .navigationTitle("Collage")
            
            // Save button
            if images.count == 2 {
                Button(action: {
                    saveCollagedImage(image1: images[0], image2: images[1])
                }) {
                    Text("Save Collage")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text("The collage has been saved to your photo library."), dismissButton: .default(Text("OK")))
        }
    }

    func saveCollagedImage(image1: UIImage, image2: UIImage) {
        let size = CGSize(width: image1.size.width + image2.size.width, height: max(image1.size.height, image2.size.height))
        UIGraphicsBeginImageContext(size)
        image1.draw(in: CGRect(x: 0, y: 0, width: image1.size.width, height: size.height))
        image2.draw(in: CGRect(x: image1.size.width, y: 0, width: image2.size.width, height: size.height))
        let collagedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let collagedImage = collagedImage {
            UIImageWriteToSavedPhotosAlbum(collagedImage, nil, nil, nil)
            showAlert = true // Show success alert
        }
    }
}
