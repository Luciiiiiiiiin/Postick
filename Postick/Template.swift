//
//  Template.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/24.
//

import Foundation
import SwiftUI

protocol Template {
    func generateCollage(images: [UIImage]) -> UIImage?
}

struct VerticalTemplate: Template {
    func generateCollage(images: [UIImage]) -> UIImage? {
        guard images.count == 2 else { return nil }
        
        let size = CGSize(width: images[0].size.width, height: images[0].size.height + images[1].size.height)
        UIGraphicsBeginImageContext(size)
        
        images[0].draw(in: CGRect(x: 0, y: 0, width: size.width, height: images[0].size.height))
        images[1].draw(in: CGRect(x: 0, y: images[0].size.height, width: size.width, height: images[1].size.height))
        
        let collagedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return collagedImage
    }
}

struct HorizontalTemplate: Template {
    func generateCollage(images: [UIImage]) -> UIImage? {
        guard images.count == 2 else { return nil }
        
        let size = CGSize(width: images[0].size.width + images[1].size.width, height: images[0].size.height)
        UIGraphicsBeginImageContext(size)
        
        images[0].draw(in: CGRect(x: 0, y: 0, width: images[0].size.width, height: size.height))
        images[1].draw(in: CGRect(x: images[0].size.width, y: 0, width: images[1].size.width, height: size.height))
        
        let collagedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return collagedImage
    }
}

