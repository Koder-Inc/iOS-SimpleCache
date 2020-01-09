//
//  SimpleCache+Public.swift
//  
//
//  Created by Aaron Satterfield on 1/9/20.
//

import Foundation
import UIKit

extension SimpleCache {
    
    public static func save(image: UIImage, for key: CacheKey, level: CacheLevel = .disk) {
        shared.save(image: image, for: key)
    }
    
    public static func object(for key: CacheKey) -> UIImage? {
        return shared.object(for: key)
    }
    
    public static func save(data: Data, for key: CacheKey) {
        shared.save(data: data, for: key)
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
    
    @discardableResult
    public static func save<T: Codable>(_ codable: T, for path: String) -> Bool {
        let key = CacheKey(path: path)
        return shared.save(codable, for: key)
    }
    
    @discardableResult
    public static func save<T: Codable>(_ codables: [T], for path: String) -> Bool {
        let key = CacheKey(path: path)
        return shared.save(codables, for: key)
    }
    
    @discardableResult
    public static func insert<T: Codable>(_ codables: [T], for path: String) -> Bool {
        let key = CacheKey(path: path)
        return shared.insert(codables, for: key)
    }
    
    @discardableResult
    public static func append<T: Codable>(_ codables: [T], for path: String) -> Bool {
        let key = CacheKey(path: path)
        return shared.append(codables, for: key)
    }
    
    @discardableResult
    public static func remove<T: SimplyCacheable>(_ itemId: String, of type: T.Type, for path: String) -> Bool {
        let key = CacheKey(path: path)
        return shared.remove(itemId, with: type, for: key)
    }
    
    @discardableResult
    public static func replace<T: SimplyCacheable>(_ itemId: String, with newItem: T, for path: String) -> Bool {
        let key = CacheKey(path: path)
        return shared.replace(itemId, with: newItem, for: key)
    }
    
    @discardableResult
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
    
    public static func removeAll(in path: String) -> Bool {
        let url = shared.diskCacheUrl.appendingPathComponent(path)
        return shared.removeAll(at: url)
    }
    
}