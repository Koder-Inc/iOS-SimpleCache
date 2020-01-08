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
    
    private static var shared = SimpleCache()
    private var memoryCache = NSCache<CacheKey, UIImage>()
    private lazy var fileManager = FileManager.default
    private lazy var diskCacheUrl = getDiskCacheURL()
    private lazy var encoder = JSONEncoder()
    private lazy var decoder = JSONDecoder()

    
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

    
}
