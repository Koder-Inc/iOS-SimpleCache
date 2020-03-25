//
//  SimpleCache+Public.swift
//  
//
//  Created by Aaron Satterfield on 1/9/20.
//

import Foundation

extension SimpleCache {
    
    public static func save(data: Data, for key: CacheKey) {
        shared.save(data: data, for: key)
    }
    
    public static func save<T: Codable>(_ codable: T, for path: String, completion: @escaping (Bool) -> Void) {
        let key = CacheKey(path: path)
        shared.save(codable, for: key, completion: completion)
    }
    
    public static func save<T: Codable>(_ codables: [T], for path: String, completion: @escaping (Bool) -> Void) {
        let key = CacheKey(path: path)
        shared.save(codables, for: key, completion: completion)
    }
    
    public static func insert<T: Codable>(_ codables: [T], for path: String, completion: @escaping (Bool) -> Void) {
        let key = CacheKey(path: path)
        shared.insert(codables, for: key, completion: completion)
    }
    
    public static func append<T: Codable>(_ codables: [T], for path: String, completion: @escaping (Bool) -> Void) {
        let key = CacheKey(path: path)
        shared.append(codables, for: key, completion: completion)
    }
    
    public static func remove<T: SimplyCacheable>(_ itemId: String, of type: T.Type, for path: String, completion: @escaping (Bool) -> Void) {
        let key = CacheKey(path: path)
        shared.remove(itemId, with: type, for: key, completion: completion)
    }
    
    public static func replace<T: SimplyCacheable>(_ itemId: String, with newItem: T, for path: String, completion: @escaping (Bool) -> Void) {
        let key = CacheKey(path: path)
        shared.replace(itemId, with: newItem, for: key, completion: completion)
    }
    
    public static func get<T: Codable>(for path: String, as type: T.Type) -> T? {
        let key = CacheKey(path: path)
        return shared.get(for: key, as: type)
    }
    
    public static func getDirectory(path: String) -> URL {
        return shared.diskCacheUrl.appendingPathComponent(path)
    }

    public static var decoder: JSONDecoder {
        return shared.decoder
    }
    
    @discardableResult
    public static func removeAll(in path: String) -> Bool {
        let url = shared.diskCacheUrl.appendingPathComponent(path)
        return shared.removeAll(at: url)
    }
    
}

// MARK: -
#if os(iOS)
import UIKit

extension SimpleCache {
    
    // MARK: iOS Specific Functions
    public static func save(image: UIImage, for key: CacheKey, level: CacheLevel = .disk) {
        shared.save(image: image, for: key)
    }
    
    public static func object(for key: CacheKey, completion: @escaping (UIImage?) -> Void) {
        shared.object(for: key, completion: completion)
    }
    
    @discardableResult
    public static func downloadImage(from url: URL, completion: ((_ image: UIImage?) -> Void)?) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
            guard let imageData = data, let image = UIImage(data: imageData) else {
                return
            }
            let key = CacheKey(url: url)
            save(image: image, for: key)
            completion?(image)
        })
        task.resume()
        return task
    }
    
}
#endif
