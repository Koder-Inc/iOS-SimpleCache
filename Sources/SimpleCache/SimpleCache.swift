import Foundation
import UIKit

public typealias SimplyCacheable = Codable & SimplyCacheIdentifiable

public protocol SimplyCacheIdentifiable {
    var cacheItemId: String { get }
}

public enum CacheLevel: Int {
    case memory, disk
}

open class SimpleCache {
    
    internal static var shared = SimpleCache()
    internal var memoryCache = NSCache<CacheKey, UIImage>()
    internal lazy var fileManager = FileManager.default
    internal lazy var diskCacheUrl = getDiskCacheURL()
    internal lazy var encoder = JSONEncoder()
    internal lazy var decoder = JSONDecoder()

    
    func save(image: UIImage, for key: CacheKey, level: CacheLevel = .disk) {
        memoryCache.setObject(image, forKey: key)
        if level.rawValue >= CacheLevel.disk.rawValue {
            saveImageToDisk(image: image, for: key)
        }
    }
    
    @discardableResult
    func save(data: Data, for key: CacheKey) -> Bool {
        do {
            try saveDataToDisk(data: data, for: key)
            return true
        } catch {
            return false
        }
    }
    
    func object(for key: CacheKey) -> UIImage? {
        if let i = memoryCache.object(forKey: key) {
            return i
        }
        if let i = getImageFromDisk(for: key) {
            return i
        }
        return nil
    }
    
    @discardableResult
    func save<T: Codable>(_ codable: T, for key: CacheKey) -> Bool {
        do {
            let data = try encoder.encode(codable)
            try saveDataToDisk(data: data, for: key)
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    func save<T: Codable>(_ codables: [T], for key: CacheKey) -> Bool {
        do {
            let data = try encoder.encode(codables)
            try saveDataToDisk(data: data, for: key)
            return true
        } catch {
            return false
        }
    }
    
    func append<T: Codable>(_ codables: [T], for key: CacheKey) -> Bool {
        var existingData: [T] = []
        if let data = get(for: key, as: [T].self) {
            existingData = data
        }
        existingData.append(contentsOf: codables)
        do {
            let data = try encoder.encode(existingData)
            try saveDataToDisk(data: data, for: key)
            return true
        } catch {
            return false
        }
    }
    
    func insert<T: Codable>(_ codables: [T], for key: CacheKey) -> Bool {
        var existingData: [T] = []
        if let data = get(for: key, as: [T].self) {
            existingData = data
        }
        existingData.insert(contentsOf: codables, at: 0)
        do {
            let data = try encoder.encode(existingData)
            try saveDataToDisk(data: data, for: key)
            return true
        } catch {
            return false
        }
    }
    
    func remove<T: SimplyCacheable>(_ itemId: String, with type: T.Type, for key: CacheKey) -> Bool {
        guard var existingData = get(for: key, as: [T].self) else {
            return false
        }
        existingData.removeAll(where: {$0.cacheItemId == itemId})
        return save(existingData, for: key)
    }
    
    func replace<T: SimplyCacheable>(_ itemId: String, with newItem: T, for key: CacheKey) -> Bool  {
        guard var existingData = get(for: key, as: [T].self) else {
            return false
        }
        guard let index = existingData.firstIndex(where: {$0.cacheItemId == itemId}) else { return false }
        existingData[index] = newItem
        return save(existingData, for: key)
    }
        
    func get<T: Codable>(for key: CacheKey, as type: T.Type) -> T? {
        let url = fileUrl(for: key)
        do {
            let data = try Data(contentsOf: url)
            let item = try decoder.decode(type, from: data)
            return item
        } catch {
            return nil
        }
    }
    
    func removeAll(at url: URL) -> Bool {
        do {
            try fileManager.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
    
}

extension SimpleCache {
    
    private func getDiskCacheURL() -> URL {
        do {
            let directory = try self.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return directory.appendingPathComponent("SimpleCache")
        } catch {
            fatalError("Could not find cache directory")
        }
    }
    
    @discardableResult
    private func saveImageToDisk(image: UIImage, for key: CacheKey) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return false
        }
        do {
            try saveDataToDisk(data: data, for: key)
            return true
        } catch {
            return false
        }
    }
    
    private func saveDataToDisk(data: Data, for key: CacheKey) throws {
        let url = fileUrl(for: key)
        try? fileManager.removeItem(at: url)
        let directory = url.path.replacingOccurrences(of: url.lastPathComponent, with: "")
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        fileManager.createFile(atPath: url.path, contents: nil, attributes: nil)
        try data.write(to: url)
    }
    
    private func getImageFromDisk(for key: CacheKey) -> UIImage? {
        guard let data = try? Data(contentsOf: fileUrl(for: key)),
            let image = UIImage(data: data) else {
                return nil
        }
        return image
    }
    
    private func fileUrl(for key: CacheKey) -> URL {
        return diskCacheUrl.appendingPathComponent(key.filename)
    }
    
}
