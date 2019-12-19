//
//  Extension+UIImage.swift
//  
//
//  Created by Aaron Satterfield on 10/8/19.
//

import Foundation
import UIKit

extension UIImage {
    
    public func save(for key: CacheKey) {
        SimpleCache.save(image: self, for: key, level: .memory)
    }
    
}
