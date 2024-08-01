//
//  PhotoPicker.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/21.
//  This file takes charge of the photo picker view and how user can select photo and add them

import Foundation
import SwiftUI
import PhotosUI

// PhotoPicker struct conforms to UIViewControllerRepresentable to use PHPickerViewController in SwiftUI.
struct PhotoPicker: UIViewControllerRepresentable {

    // Coordinator class acts as a delegate for PHPickerViewController.
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPicker

        // Initializer to link the Coordinator with the parent PhotoPicker.
        init(parent: PhotoPicker) {
            self.parent = parent
        }

        // Delegate method called when the user finishes picking photos.
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss the picker.
            picker.dismiss(animated: true)

            // Array to hold the selected images.
            var images: [UIImage] = []

            // Dispatch group to manage the asynchronous image loading.
            let dispatchGroup = DispatchGroup()

            // Loop through the selected results, up to the selection limit.
            for result in results.prefix(parent.selectionLimit) {
                // Enter the dispatch group for each result.
                dispatchGroup.enter()

                // Load the image object.
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    // If the object is a UIImage, add it to the images array.
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    // Leave the dispatch group once loading is complete.
                    dispatchGroup.leave()
                }
            }

            // Notify the main queue when all images have been loaded.
            dispatchGroup.notify(queue: .main) {
                // Pass the selected images back to the parent.
                self.parent.onPhotosSelected(images)
            }
        }
    }

    // Closure to handle the selected photos.
    var onPhotosSelected: ([UIImage]) -> Void
    
    // The maximum number of images that can be selected.
    var selectionLimit: Int

    // Create and return a Coordinator instance.
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // Create and configure the PHPickerViewController.
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        // Set the filter to only show images.
        config.filter = .images
        // Set the selection limit.
        config.selectionLimit = selectionLimit
        // Create the PHPickerViewController with the configuration.
        let picker = PHPickerViewController(configuration: config)
        // Assign the coordinator as the delegate.
        picker.delegate = context.coordinator
        return picker
    }

    // Update the PHPickerViewController if needed. (Currently, no updates required)
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}
