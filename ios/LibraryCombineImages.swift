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
        images: [[String: Any]],
        resultSavePath: NSString,
        mainImageIndex: NSInteger,
        backgroundColor: UIColor
    ) -> String? {
        if images.isEmpty {
            return "LibraryCombineImages.combineImages.emptyArray"
        }
        
        let mainJson = images[mainImageIndex]
        let mainImage = mainJson["image"] as! UIImage
        let parentCenterX = mainImage.size.width / 2
        let parentCenterY = mainImage.size.height / 2
        let newImageSize = CGSize(width: mainImage.size.width, height: mainImage.size.height)
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1.0)
        backgroundColor.setFill()
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: newImageSize.width, height: newImageSize.height))
        
        for (index, json) in images.enumerated() {
            let image = json["image"] as! UIImage
            var x = parentCenterX - image.size.width / 2
            var y = parentCenterY - image.size.height / 2
            if let positions = json["positions"] as? [String: Double], let pX = positions["x"], let pY = positions["y"] {
                x = pX
                y = pY
                if x > mainImage.size.width {
                    x = mainImage.size.width - image.size.width
                }
                if y > mainImage.size.height {
                    y = mainImage.size.height - image.size.height
                }
                if x < 0 {x = 0}
                if y <= 0 {y = 0}
            }
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
