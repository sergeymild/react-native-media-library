//
//  LibrarySaveToCameraRoll.swift
//  MediaLibrary
//
//  Created by sergeymild on 03/08/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation
import CoreServices
import Photos

class Result {
    internal init(error: String? = nil, result: String? = nil) {
        self.error = error
        self.result = result
    }
    
    var error: String?
    var result: String?
}

@objc
public class LibrarySaveToCameraRoll: NSObject {
    private static func assetTypeFor(uri: NSString) -> PHAssetMediaType {
        let fileExtension = uri.pathExtension
        guard let fileUTI = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            fileExtension as CFString,
            nil
        ) else { return .unknown }
        let value = fileUTI.takeRetainedValue()
        if (UTTypeConformsTo(value, kUTTypeImage)) { return .image }
        if (UTTypeConformsTo(value, kUTTypeMovie)) { return .video }
        if (UTTypeConformsTo(value, kUTTypeAudio)) { return .audio }
        return .unknown
    }
    
    private static func normalizeAssetURLFromUri(uri: NSString) -> URL? {
        if uri.hasPrefix("/") {
            return URL(string: "file://\(uri)")
        }
        return URL(string: uri as String)
    }
    
    private static func saveBlock(
        assetType: PHAssetMediaType,
        url: URL,
        collection: PHAssetCollection?
    ) async -> Result {
        let result = Result()
        do {
            try await PHPhotoLibrary.shared().performChanges {
            let changeRequest = assetType == .video
            ? PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            : PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            
            let assetPlaceholder = changeRequest!.placeholderForCreatedAsset
            
            if let collection = collection {
                let photosAsset = PHAsset.fetchAssets(
                    in: collection,
                    options: nil
                )
                let albumChangeRequest = PHAssetCollectionChangeRequest(
                    for: collection,
                    assets: photosAsset
                )
                albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
            }
            result.error = nil
            result.result = assetPlaceholder!.localIdentifier
        }
            
        }
        catch let error {
            print(error.localizedDescription)
            result.error = error.localizedDescription
        }
        return result
    }
    
    private static func saveWithOptions(
        album: String?,
        assetType: PHAssetMediaType,
        url: URL,
        collection: PHAssetCollection?
    ) async -> Result {
        if album == nil || album!.isEmpty {
            return await saveBlock(assetType: assetType, url: url, collection: collection)
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", argumentArray: [album!])
        
        let collection = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: fetchOptions
        )
        if let collection = collection.firstObject {
            return await saveBlock(assetType: assetType, url: url, collection: collection)
        }
        
        // create new collection
        var placeholder: PHObjectPlaceholder?
        
        let result = Result()
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let createAlbum = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                    withTitle: album!
                )
                placeholder = createAlbum.placeholderForCreatedAssetCollection
            }
            // if collection was created fetch it
            if let placeholder = placeholder {
                let collection = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [placeholder.localIdentifier],
                    options: nil
                ).firstObject
                if let collection = collection {
                    return await Self.saveBlock(
                        assetType: assetType,
                        url: url,
                        collection: collection
                    )
                }
            }
        }
        catch let error {
            print(error.localizedDescription)
            result.error = error.localizedDescription
        }
        
        return result
    }
    
    @objc
    public static func saveToCameraRoll(
        localUri: NSString,
        album: String,
        callback: @escaping (String?, String?) -> Void
    ) {
        Task {
            if Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") == nil {
                return callback("kErrorNoPermissions", nil)
            }
            if localUri.pathExtension.isEmpty {
                return callback("kErrorNoFileExtension", nil);
            }
            
            let assetType = Self.assetTypeFor(uri: localUri)
            if assetType == .audio || assetType == .unknown {
                return callback("kErrorUnsupportedAsset", nil)
            }
            
            guard let assetUrl = Self.normalizeAssetURLFromUri(uri: localUri) else {
                return callback("kErrorNotValidUri", nil)
            }
            
            let result = await saveWithOptions(
                album: album,
                assetType: assetType,
                url: assetUrl,
                collection: nil
            )
            if let error = result.error {
                return callback(error, nil)
            }
            if let id = result.result {
                return MediaAssetManager.fetchAsset(identifier: id) { data in
                    if let data = data {
                        return callback(nil, data)
                    }
                    callback("kErrorFetchAssetData", nil)
                }
            }
            return callback("kErrorSaveToCameraRoll", nil)
        }
    }
}
