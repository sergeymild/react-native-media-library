//
//  LibraryImageResize.swift
//  MediaLibrary
//
//  Created by sergeymild on 05/08/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation

@objc
public class LibraryImageResize: NSObject {
    @objc
    public static func resize(
        uri: NSString,
        width: NSNumber,
        height: NSNumber,
        format: NSString,
        resultSavePath: NSString
    ) -> String? {
        guard let image = LibraryImageSize.image(path: uri as String) else {
            return "LibraryImageResize.image.notExists"
        }
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let imageRatio = imageWidth / imageHeight
        var targetSize: CGSize = .zero
        
        if (width.floatValue >= 0) {
            targetSize.width = CGFloat(width.floatValue)
            targetSize.height = targetSize.width / imageRatio
        }
        
        if (height.floatValue >= 0) {
            targetSize.height = CGFloat(height.floatValue)
            targetSize.width = targetSize.width <= 0 ? imageRatio * targetSize.height : targetSize.width
        }
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: .init(origin: .zero, size: targetSize))
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = finalImage else {
            return "LibraryImageResize.image.emptyContext"
        }
        
        return LibraryImageSize.save(image: finalImage, format: format, path: resultSavePath)
    }
}
