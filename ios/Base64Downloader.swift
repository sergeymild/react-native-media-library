//
//  Base64Downloader.swift
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 02/01/2024.
//  Copyright © 2024 Facebook. All rights reserved.
//

import Foundation

@objc
public class Base64Downloader: NSObject {
    @objc
    public static func download(url: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: url) else { return completion(nil) }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data else { return completion(nil) }
            completion("{\"base64\": \"\(data.base64EncodedString())\"}")
        }.resume()
    }
}
