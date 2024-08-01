//
//  Template.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/24.
//  This file holds template protocol which users can choose different protocol to decide how they want to combine the
//  image

import Foundation
import SwiftUI

// Protocol defining a template for generating a collage from an array of images.
protocol Template {
    func generateCollage(images: [UIImage]) -> UIImage?
}

// Struct implementing the Template protocol to generate a vertical collage.
struct VerticalTemplate: Template {
    func generateCollage(images: [UIImage]) -> UIImage? {
        // Ensure exactly two images are provided.
        guard images.count == 2 else { return nil }
        
        // Calculate the size of the final collage image.
        let size = CGSize(width: images[0].size.width, height: images[0].size.height + images[1].size.height)
        
        // Begin a new image context with the calculated size.
        UIGraphicsBeginImageContext(size)
        
        // Draw the first image at the top.
        images[0].draw(in: CGRect(x: 0, y: 0, width: size.width, height: images[0].size.height))
        // Draw the second image below the first image.
        images[1].draw(in: CGRect(x: 0, y: images[0].size.height, width: size.width, height: images[1].size.height))
        
        // Get the resulting collage image from the current image context.
        let collagedImage = UIGraphicsGetImageFromCurrentImageContext()
        // End the image context to free up resources.
        UIGraphicsEndImageContext()
        
        // Return the generated collage image.
        return collagedImage
    }
}

// Struct implementing the Template protocol to generate a horizontal collage.
struct HorizontalTemplate: Template {
    func generateCollage(images: [UIImage]) -> UIImage? {
        // Ensure exactly two images are provided.
        guard images.count == 2 else { return nil }
        
        // Calculate the size of the final collage image.
        let size = CGSize(width: images[0].size.width + images[1].size.width, height: images[0].size.height)
        
        // Begin a new image context with the calculated size.
        UIGraphicsBeginImageContext(size)
        
        // Draw the first image on the left.
        images[0].draw(in: CGRect(x: 0, y: 0, width: images[0].size.width, height: size.height))
        // Draw the second image to the right of the first image.
        images[1].draw(in: CGRect(x: images[0].size.width, y: 0, width: images[1].size.width, height: size.height))
        
        // Get the resulting collage image from the current image context.
        let collagedImage = UIGraphicsGetImageFromCurrentImageContext()
        // End the image context to free up resources.
        UIGraphicsEndImageContext()
        
        // Return the generated collage image.
        return collagedImage
    }
}
