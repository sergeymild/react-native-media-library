//
//  AssetsManager.swift
//  MediaLibrary
//
//  Created by sergeymild on 01/08/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation
import Photos

class AssetLocation: Encodable {
    let longitude: Double
    let latitude: Double
    
    internal init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }
}

private struct Collection: Encodable {
    let id: String
    let filename: String
    let count: Int
}

class AssetData: Encodable {
    let filename: String
    let id: String
    let creationTime: Double?
    let modificationTime: Double?
    let duration: Double
    let width: Double
    let height: Double
    let mediaType: String
    let uri: String
    var url: String?
    let location: AssetLocation?
    let subtypes: [String]
    
    internal init(
        filename: String,
        id: String,
        creationTime: Double?,
        modificationTime: Double?,
        duration: Double,
        width: Double,
        height: Double,
        mediaType: String,
        uri: String,
        url: String?,
        location: AssetLocation?,
        subtypes: [String]
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
        self.subtypes = subtypes
    }
}

extension PHAsset {
    func asyncRequestUrl() async -> URL? {
        await withCheckedContinuation { continuation in
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            
            requestContentEditingInput(with: options) { input, info in
                guard let url = input?.fullSizeImageURL else {
                    return continuation.resume(returning: nil)
                }
                continuation.resume(returning: url)
            }
        }
    }
    
    func value(key: String) -> String {
        return value(forKey: key) as! String
    }
    
    func creationDate() -> Double? {
        guard let date = creationDate else { return nil }
        let interval = date.timeIntervalSince1970
        let intervalMs = interval * 1000.0
        return intervalMs
    }
    
    func modificationDate() -> Double? {
        guard let date = modificationDate else { return nil }
        let interval = date.timeIntervalSince1970
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
    
    func mediaSubtypeTypes() -> [String] {
        var subtypes: [String] = []
        if mediaSubtypes.contains(.photoPanorama) {
            subtypes.append("photoPanorama")
        }
        if mediaSubtypes.contains(.photoHDR) {
            subtypes.append("photoHDR")
        }
        if mediaSubtypes.contains(.photoScreenshot) {
            subtypes.append("photoScreenshot")
        }
        if mediaSubtypes.contains(.photoLive) {
            subtypes.append("photoLive")
        }
        if mediaSubtypes.contains(.photoDepthEffect) {
            subtypes.append("photoDepthEffect")
        }
        if mediaSubtypes.contains(.videoStreamed) {
            subtypes.append("videoStreamed")
        }
        if mediaSubtypes.contains(.videoHighFrameRate) {
            subtypes.append("videoHighFrameRate")
        }
        if mediaSubtypes.contains(.videoTimelapse) {
            subtypes.append("videoTimelapse")
        }
        if #available(iOS 15, *) {
            if mediaSubtypes.contains(.videoCinematic) {
                subtypes.append("videoCinematic")
            }
        }
        return subtypes
    }
}

extension PHImageManager {
    func exportSession(asset: PHAsset) async -> (AVAssetExportSession?) {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            requestExportSession(
                forVideo: asset,
                options: options,
                exportPreset: AVAssetExportPresetMediumQuality
            ) { session, _ in
                continuation.resume(returning: session)
            }
        }
    }

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
    public static func fetchRawAsset(identifier: String) -> PHAsset? {
        let identifier = identifier.replacingOccurrences(of: "ph://", with: "")
        let options = PHFetchOptions()
        options.includeHiddenAssets = true;
        options.includeAllBurstAssets = true;
        options.fetchLimit = 1;
        return PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: options).firstObject
    }
    
    private static func assetToData(asset: PHAsset, isSloMo: Bool, url: String?) -> AssetData {
        var location: AssetLocation?
        if let loc = asset.location {
            location = AssetLocation(
                longitude: loc.coordinate.longitude,
                latitude: loc.coordinate.latitude
            )
        }
        return AssetData(
            filename: asset.value(key: "filename"),
            id: asset.localIdentifier,
            creationTime: asset.creationDate(),
            modificationTime: asset.modificationDate(),
            duration: asset.duration,
            width: Double(asset.pixelWidth),
            height: Double(asset.pixelHeight),
            mediaType: asset.mediaType(),
            uri: "ph://\(asset.localIdentifier)",
            url: url,
            location: location,
            subtypes: asset.mediaSubtypeTypes()
        )
    }
    
    private static func assetToData(asset: PHAsset) async -> AssetData {
        let (url, isSloMo) = await fetchAssetUrl(asset: asset)
        return assetToData(asset: asset, isSloMo: isSloMo, url: url?.absoluteString)
    }
    
    @objc
    public static func fetchAsset(identifier: String, completion: @escaping (String?) -> Void) {
        Task {
            let identifier = identifier.replacingOccurrences(of: "ph://", with: "")
            let options = PHFetchOptions()
            options.includeHiddenAssets = true;
            options.includeAllBurstAssets = true;
            options.fetchLimit = 1;
            let rawAsset = fetchRawAsset(identifier: identifier)
            
            guard let asset = rawAsset else { return completion(nil) }
            
            let data = try! JSONEncoder().encode(await assetToData(asset: asset))
            
            completion(String(data: data, encoding: .utf8))
        }
    }
    
    @objc
    public static func fetchAssets(
        limit: Int,
        offset: Int,
        sortBy: String?,
        sortOrder: String?,
        mediaType: [String],
        collectionId: String?,
        completion: @escaping (String) -> Void
    ) {
        Task {
            var collection: PHAssetCollection?
            if let cId = collectionId {
                collection = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [cId],
                    options: nil
                ).firstObject
            }
            
            let options = PHFetchOptions()
            options.includeAllBurstAssets = false
            options.includeHiddenAssets = false
            
            if !(mediaType.contains("photo") && mediaType.contains("video")) {
                var type: PHAssetMediaType = .image
                if mediaType.contains("video") { type = .video }
                let predicate = NSPredicate(format: "mediaType = %d", type.rawValue)
                options.predicate = predicate
            }
            
            if limit > 0 && offset == -1 { options.fetchLimit = limit }
            
            if sortBy != nil && !sortBy!.isEmpty {
                if sortBy! == "creationTime" || sortBy! == "modificationTime" {
                    let ascending = sortOrder == "asc"
                    let key = sortBy! == "creationTime" ? "creationDate" : "modificationDate"
                    options.sortDescriptors = [.init(key: key, ascending: ascending)]
                }
            }
            
            let result = collection != nil
            ? PHAsset.fetchAssets(in: collection!, options: options)
            : PHAsset.fetchAssets(with: options)
            
            let totalCount = result.count
            let startIndex = max(0, offset == -1 ? -1 : offset + 1)
            let limit = limit == -1 ? 10 : limit
            let endIndex = min(startIndex + limit, totalCount)
            
            if (startIndex == endIndex) { return completion("[]") }
            
            
            
            var assets: [AssetData] = []
            var i = startIndex
            while i < endIndex {
                let asset = result.object(at: i)
                assets.append(assetToData(asset: asset, isSloMo: false, url: nil))
                i += 1
            }
            
            let data = try! JSONEncoder().encode(assets)
            completion(String(data: data, encoding: .utf8) ?? "[]")
        }
    }

    public static func fetchAssetUrl(asset: PHAsset) async -> (URL?, Bool) {
        if asset.mediaType == .image {
            guard let url = await asset.asyncRequestUrl() else { return (nil, false) }
            return (url, false)
        }
        
        if asset.mediaType == .video {
            let (videoAsset, isSloMo) = await PHImageManager.default()
                .asyncRequestAVAsset(forVideo: asset, fetchOriginal: false)
            if let video = videoAsset as? AVURLAsset {
                return (video.url, isSloMo)
            }
            return (nil, isSloMo)
        }
        
        return (nil, false)
    }
    
    
    public static func fetchCollectionCount(_ collection: PHAssetCollection) async -> Int {
        await withCheckedContinuation { cont in
            let options = PHFetchOptions()
            options.includeAllBurstAssets = false
            options.includeHiddenAssets = false
            options.fetchLimit = 0
            cont.resume(returning: PHAsset.fetchAssets(in: collection, options: options).count)
        }
    }
    
    @objc
    public static func fetchCollections(completion: @escaping(String) -> Void) {
        
        Task {
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            
            var collections: [Collection] = []
            var index = 0
            var total = smartAlbums.count
            
            while total > 0 {
                let asset = smartAlbums.object(at: index)
                collections.append(.init(
                    id: asset.localIdentifier,
                    filename: asset.localizedTitle ?? "unknown",
                    count: await fetchCollectionCount(asset)
                ))
                total -= 1
                index += 1
            }
            
            index = 0
            total = albums.count

            while total > 0 {
                let asset = albums.object(at: index)
                collections.append(.init(
                    id: asset.localIdentifier,
                    filename: asset.localizedTitle ?? "unknown",
                    count: await fetchCollectionCount(asset)
                ))
                total -= 1
                index += 1
            }
            
            completion(String(data: try! JSONEncoder().encode(collections), encoding: .utf8)!)
        }
    }
    
    @objc
    public static func exportVideo(
        identifier: String,
        resultSavePath: NSString,
        completion: @escaping (Bool) -> Void
    ) {
        Task {
            let identifier = identifier.replacingOccurrences(of: "ph://", with: "")
            let options = PHFetchOptions()
            options.includeHiddenAssets = true;
            options.includeAllBurstAssets = true;
            options.fetchLimit = 1;
            let rawAsset = fetchRawAsset(identifier: identifier)
            
            guard let asset = rawAsset else { return completion(false) }
            
            guard let exportSession = await PHImageManager.default().exportSession(asset: asset) else {
                return completion(false)
            }
            
            ensurePath(path: resultSavePath)
            
            exportSession.outputURL = toFilePath(path: resultSavePath)
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            
            await exportSession.export()
            switch exportSession.status {
            case .failed:
                print(exportSession.error ?? "NO ERROR")
                completion(false)
            case .cancelled:
                completion(false)
            case .completed:
                completion(true)
            case .unknown:
                completion(false)
            case .waiting:
                completion(false)
            case .exporting:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
}
