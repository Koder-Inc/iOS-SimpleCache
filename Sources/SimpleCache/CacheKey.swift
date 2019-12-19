//
//  CacheKey.swift
//  
//
//  Created by Aaron Satterfield on 10/8/19.
//

import Foundation
import UIKit

public class CacheKey: NSObject{
    
    private(set) var id: String
    private var fileExtension: String?
    
    public init(id: String, size: CGSize? = nil) {
        self.id = id
        if let size = size {
            self.id.append("-\(size.width)-\(size.height)")
        }
        super.init()
    }
    
    public init(url: URL) {
        self.id = CacheKey.keyId(for: url)
        self.fileExtension = url.pathExtension
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        return self.id == (object as? CacheKey)?.id
    }
    
    var filename: String {
        if let ext = fileExtension {
            return id.appending(".\(ext)")
        }
        return id.appending(".jpeg")
    }
    
}

extension CacheKey {
    
    static func keyId(for url: URL) -> String {
        var id = url.path.replacingOccurrences(of: "/", with: "-")
        id = id.replacingOccurrences(of: ".", with: "-")
        return id.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    }
    
}
