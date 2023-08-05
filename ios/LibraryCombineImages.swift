//
//  LibraryCombineImages.swift
//  MediaLibrary
//
//  Created by sergeymild on 05/08/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation

@objc
public class LibraryCombineImages: NSObject {
    @objc
    public static func combineImages(
        images: [UIImage],
        resultSavePath: NSString
    ) -> String? {
        if images.isEmpty {
            return "LibraryCombineImages.combineImages.emptyArray"
        }
        
        let firstImage = images.first!
        let parentCenterX = firstImage.size.width / 2
        let parentCenterY = firstImage.size.height / 2
        var newImageSize = CGSize(width: firstImage.size.width, height: firstImage.size.height)
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, UIScreen.main.scale)
        
        for image in images {
            let x = parentCenterX - image.size.width / 2
            let y = parentCenterY - image.size.height / 2
            image.draw(at: .init(x: x, y: y))
        }
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = finalImage else {
            return "CombineImages.combineImages.emptyContext";
        }
        
        return LibraryImageSize.save(image: finalImage, format: "png", path: resultSavePath)
    }
}
