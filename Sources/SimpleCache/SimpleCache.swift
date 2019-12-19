import Foundation
import UIKit

public enum CacheLevel: Int {
    case memory, disk
}

open class SimpleCache {
    
    private static var shared = SimpleCache()
    private var memoryCache = NSCache<CacheKey, UIImage>()
    private lazy var fileManager = FileManager.default
    private lazy var diskCacheUrl = getDiskCacheURL()
    
    func save(image: UIImage, for key: CacheKey, level: CacheLevel = .disk) {
        memoryCache.setObject(image, forKey: key)
        if level.rawValue >= CacheLevel.disk.rawValue {
            saveImageToDisk(image: image, for: key)
        }
    }
    
    func save(data: Data, for key: CacheKey) {
        saveDataToDisk(data: data, for: key)
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
    
    private func saveImageToDisk(image: UIImage, for key: CacheKey) {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return
        }
        saveDataToDisk(data: data, for: key)
    }
    
    private func saveDataToDisk(data: Data, for key: CacheKey) {
        try? data.write(to: fileUrl(for: key))
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
    
}
