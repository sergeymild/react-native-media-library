//
//  LibraryImageSize.swift
//  MediaLibrary
//
//  Created by sergeymild on 03/08/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation
import React

private struct Size: Codable {
    let width: Double
    let height: Double
}

private func toFilePath(path: NSString) -> URL {
    if path.hasPrefix("file://") {
        return URL(string: path as String)!
    }
    return URL(string: "file://\(path)")!
}

@objc
public class LibraryImageSize: NSObject {
    private static func imageSource(path: String) -> RCTImageSource? {
        return RCTImageSource(
            urlRequest: RCTConvert.nsurlRequest(path),
            size: .zero,
            scale: 1.0
        )
    }
    
    @objc
    public static func image(path: String) -> UIImage? {
        guard let source = imageSource(path: path),
              let url = source.request.url,
              let scheme = url.scheme?.lowercased()
        else {
            return nil
        }
        
        var image: UIImage? = nil;
        if scheme == "file" {
            image = RCTImageFromLocalAssetURL(url) ?? RCTImageFromLocalBundleAssetURL(url)
        } else if scheme == "data" || scheme.hasPrefix("http") {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }
        
        var scale = source.scale
        if scale == 1.0 && source.size.width > 0, let image = image {
          // If no scale provided, set scale to image width / source width
            scale = CGFloat(image.cgImage?.width ?? 1) / source.size.width;
        }
        
        if scale > 1.0, let i = image, let cgImage = i.cgImage {
            image = UIImage(
                cgImage: cgImage,
                scale: scale,
                orientation: i.imageOrientation
            )
        }
        
        return image
    }
    
    
    @objc
    public static func getSizes(paths: [String], completion: @escaping (String) -> Void) {
        Task {
            var sizes: [Size] = []
            for path in paths {
                if path.hasPrefix("ph://") {
                    if let asset = MediaAssetManager.fetchRawAsset(identifier: path) {
                        let size = Size(width: Double(asset.pixelWidth), height: Double(asset.pixelHeight))
                        sizes.append(size)
                    }
                    continue
                }
                
                guard let image = image(path: path) else {
                    continue
                }
                sizes.append(.init(width: image.size.width, height: image.size.height))
            }
            let result = String(data: (try! JSONEncoder().encode(sizes)), encoding: .utf8) ?? "[]"
            completion(result)
        }
    }
    
    @objc
    public static func save(image: UIImage, format: NSString, path: NSString) -> Bool {
        let folderPath = path.deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: path as String) {
                try FileManager.default.removeItem(atPath: path as String)
            }
            let finalPath = toFilePath(path: path)
            if format == "png" {
                guard let data = image.pngData() else { return false }
                try data.write(to: finalPath, options: .atomic)
                return true
            }
            guard let data = image.jpegData(compressionQuality: 1.0) else { return false }
            try data.write(to: finalPath, options: .atomic)
            return true
        } catch {
            debugPrint("save(image.Error", error)
        }
        return false
    }
}
