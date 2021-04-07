import Foundation

public typealias SimplyCacheable = Codable & SimplyCacheIdentifiable

public protocol SimplyCacheIdentifiable {
    var cacheItemId: String { get }
}

public enum CacheLevel: Int {
    case memory, disk
}

open class SimpleCache {
    
    internal static var shared = SimpleCache()
    #if os(iOS)
    internal var memoryCache = NSCache<CacheKey, UIImage>()
    #endif
    internal lazy var fileManager = FileManager.default
    internal lazy var diskCacheUrl = getDiskCacheURL()
    internal lazy var encoder = JSONEncoder()
    internal lazy var decoder = JSONDecoder()
    
    func save(data: Data, for key: CacheKey, completion: ((Bool) -> Void)? = nil) {
        saveDataToDisk(data: data, for: key) { error in
            completion?(error == nil)
        }
    }
    
    func save<T: Codable>(_ codable: T, for key: CacheKey, completion: @escaping (Bool) -> Void) {
        do {
            let data = try encoder.encode(codable)
            saveDataToDisk(data: data, for: key) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func save<T: Codable>(_ codables: [T], for key: CacheKey, completion: @escaping (Bool) -> Void) {
        do {
            let data = try encoder.encode(codables)
            saveDataToDisk(data: data, for: key) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func append<T: Codable>(_ codables: [T], for key: CacheKey, completion: @escaping (Bool) -> Void) {
        var existingData: [T] = []
        if let data = get(for: key, as: [T].self) {
            existingData = data
        }
        existingData.append(contentsOf: codables)
        do {
            let data = try encoder.encode(existingData)
            saveDataToDisk(data: data, for: key) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func insert<T: Codable>(_ codables: [T], for key: CacheKey, completion: @escaping (Bool) -> Void) {
        var existingData: [T] = []
        if let data = get(for: key, as: [T].self) {
            existingData = data
        }
        existingData.insert(contentsOf: codables, at: 0)
        do {
            let data = try encoder.encode(existingData)
            saveDataToDisk(data: data, for: key) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func remove<T: SimplyCacheable>(_ itemId: String, with type: T.Type, for key: CacheKey, completion: @escaping (Bool) -> Void) {
        guard var existingData = get(for: key, as: [T].self) else {
            completion(false)
            return
        }
        existingData.removeAll(where: {$0.cacheItemId == itemId})
        save(existingData, for: key, completion: completion)
    }
    
    func replace<T: SimplyCacheable>(_ itemId: String, with newItem: T, for key: CacheKey, completion: @escaping (Bool) -> Void) {
        guard var existingData = get(for: key, as: [T].self) else {
            completion(false)
            return
        }
        guard let index = existingData.firstIndex(where: {$0.cacheItemId == itemId}) else {
            completion(false)
            return
        }
        existingData[index] = newItem
        save(existingData, for: key, completion: completion)
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
            preconditionFailure("Could not find cache directory")
        }
    }
    
    private func saveDataToDisk(data: Data, for key: CacheKey, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let url = self.fileUrl(for: key)
                try? self.fileManager.removeItem(at: url)
                let directory = url.path.replacingOccurrences(of: url.lastPathComponent, with: "")
                try self.fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
                self.fileManager.createFile(atPath: url.path, contents: nil, attributes: nil)
                try data.write(to: url)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    private func fileUrl(for key: CacheKey) -> URL {
        return diskCacheUrl.appendingPathComponent(key.filename)
    }
}

// MARK: -
#if os(iOS)
import UIKit

extension SimpleCache {
    
    //MARK: iOS Specific Functions
    
    func save(image: UIImage, for key: CacheKey, level: CacheLevel = .disk) {
        memoryCache.setObject(image, forKey: key)
        if level.rawValue >= CacheLevel.disk.rawValue {
            saveImageToDisk(image: image, for: key)
        }
    }
    
    func object(for key: CacheKey, completion: @escaping (UIImage?) -> Void) {
        if let image = memoryCache.object(forKey: key) {
            completion(image)
            return
        }
        getImageFromDisk(for: key, completion: completion)
    }
    
    func object(for key: CacheKey) -> UIImage? {
        if let image = memoryCache.object(forKey: key) {
            return image
        }
        return getImageFromDisk(for: key)
    }
    
    private func saveImageToDisk(image: UIImage, for key: CacheKey, completion: ((Bool) -> Void)? = nil) {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            completion?(false)
            return
        }
        saveDataToDisk(data: data, for: key) { error in
            completion?(error == nil)
        }
    }
    
    private func getImageFromDisk(for key: CacheKey, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let fileURL = self?.fileUrl(for: key), let data = try? Data(contentsOf: fileURL),
                let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    private func getImageFromDisk(for key: CacheKey) -> UIImage? {
        guard let data = try? Data(contentsOf: self.fileUrl(for: key)), let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}
#endif
