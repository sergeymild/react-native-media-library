//
//  AssetsManager.swift
//  MediaLibrary
//
//  Created by sergeymild on 01/08/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation
import Photos

@objc
open class AssetLocation: NSObject {
    @objc
    public let longitude: Double
    @objc
    public let latitude: Double
    
    internal init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }
}

@objc
open class AssetData: NSObject {
    
    @objc
    public let filename: String
    @objc
    public let id: String
    @objc
    public let creationTime: Double
    @objc
    public let modificationTime: Double
    @objc
    public let duration: Double
    @objc
    public let width: Double
    @objc
    public let height: Double
    @objc
    public let mediaType: String
    @objc
    public let uri: String
    @objc
    public let url: String?
    @objc
    public let location: AssetLocation?
    @objc
    public let isSloMo: Bool
    
    internal init(
        filename: String,
        id: String,
        creationTime: Double,
        modificationTime: Double,
        duration: Double,
        width: Double,
        height: Double,
        mediaType: String,
        uri: String,
        url: String?,
        location: AssetLocation?,
        isSloMo: Bool
    ) {
        self.filename = filename
        self.id = id
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.duration = duration
        self.width = width
        self.height = height
        self.mediaType = mediaType
        self.url = url
        self.uri = uri
        self.location = location
        self.isSloMo = isSloMo
    }
}

extension PHAsset {
    func asyncRequestUrl() async -> String? {
        await withCheckedContinuation { continuation in
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            
            requestContentEditingInput(with: options) { input, info in
                guard let url = input?.fullSizeImageURL?.absoluteString else {
                    return continuation.resume(returning: nil)
                }
                continuation.resume(returning: url)
            }
        }
    }
    
    func value(key: String) -> String {
        return value(forKey: key) as! String
    }
    
    func creationDate() -> Double {
        let interval = creationDate!.timeIntervalSince1970
        let intervalMs = interval * 1000.0
        return intervalMs
    }
    
    func modificationDate() -> Double {
        let interval = modificationDate!.timeIntervalSince1970
        let intervalMs = interval * 1000.0
        return intervalMs
    }
    
    func mediaType() -> String {
        switch mediaType {
        case .audio: return "audio"
        case .image: return "photo"
        case .video: return "video"
        case .unknown: return "unknown"
        @unknown default:
            return "unknown"
        }
    }
}

extension PHImageManager {
    func asyncRequestAVAsset(forVideo asset: PHAsset, fetchOriginal: Bool) async -> (AVAsset?, Bool) {
        let result = await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            if fetchOriginal { options.version = .original }
            requestAVAsset(forVideo: asset, options: options) { rawAsset, _, info in
                if rawAsset is AVComposition {
                    return continuation.resume(returning: (rawAsset, true))
                }
                continuation.resume(returning: (rawAsset, false))
            }
        }
        if result.1 == false { return result }
        // slo-mo video
        let result2 = await asyncRequestAVAsset(forVideo: asset, fetchOriginal: true)
        return (result2.0, result.1)
    }
}

@objc
open class MediaAssetManager: NSObject {
    
    @objc
    public static func fetchAsset(identifier: String, completion: @escaping (AssetData?) -> Void) {
        Task {
            let identifier = identifier.replacingOccurrences(of: "ph://", with: "")
            let options = PHFetchOptions()
            options.includeHiddenAssets = true;
            options.includeAllBurstAssets = true;
            options.fetchLimit = 1;
            let rawAsset = PHAsset.fetchAssets(
                withLocalIdentifiers: [identifier],
                options: options).firstObject
            
            guard let asset = rawAsset else { return completion(nil) }

            let (absoluteUrl, isSloMo) = await Self.fetchAssetUrl(asset: asset)
            
            var location: AssetLocation?
            if let loc = asset.location {
                location = AssetLocation(
                    longitude: loc.coordinate.longitude,
                    latitude: loc.coordinate.latitude
                )
            }
            
            completion(AssetData(
                filename: asset.value(key: "filename"),
                id: asset.localIdentifier,
                creationTime: asset.creationDate(),
                modificationTime: asset.modificationDate(),
                duration: asset.duration,
                width: Double(asset.pixelWidth),
                height: Double(asset.pixelHeight),
                mediaType: asset.mediaType(),
                uri: "ph://\(asset.localIdentifier)",
                url: absoluteUrl,
                location: location,
                isSloMo: isSloMo
            ))
        }
    }

    public static func fetchAssetUrl(asset: PHAsset) async -> (String?, Bool) {
        if asset.mediaType == .image {
            guard let url = await asset.asyncRequestUrl() else { return (nil, false) }
            return (url, false)
        }
        
        if asset.mediaType == .video {
            let (videoAsset, isSloMo) = await PHImageManager.default()
                .asyncRequestAVAsset(forVideo: asset, fetchOriginal: false)
            if let video = videoAsset as? AVURLAsset {
                return (video.url.absoluteString, isSloMo)
            }
            return (nil, isSloMo)
        }
        
        return (nil, false)
    }
}
