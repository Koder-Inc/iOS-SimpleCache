//
//  CacheKey.swift
//  
//
//  Created by Aaron Satterfield on 10/8/19.
//

import Foundation
import CoreGraphics

public class CacheKey: NSObject{
    
    private(set) var path: String
    private var fileExtension: String?
    
    public init(path: String, size: CGSize? = nil) {
        self.path = path
        if let size = size {
            self.path.append("-\(size.width)-\(size.height)")
        }
        var comps = path.components(separatedBy: ".")
        if comps.count > 1 {
            fileExtension = comps.removeLast()
            self.path = comps.joined()
        }
        super.init()
    }
    
    public init(url: URL) {
        self.path = CacheKey.path(for: url)
        self.fileExtension = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        return self.path == (object as? CacheKey)?.path
    }
    
    var filename: String {
        if let ext = fileExtension, !ext.isEmpty {
            return path.appending(".\(ext)")
        }
        return path.appending(".jpeg")
    }
    
}

extension CacheKey {
    
    static func path(for url: URL) -> String {
        var id = url.path.replacingOccurrences(of: "/", with: "-")
        id = id.replacingOccurrences(of: ".", with: "-")
        return id.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    }
    
}
