//
//  File.swift
//  
//
//  Created by Aashish Tamsya on 3/27/20.
//

import UIKit

extension UIImageView {
    public func setImage(with key: CacheKey, url: URL?, options: [SimpleCacheOptions]?) {
        guard let url = url else { return }
        SimpleCache.object(for: key) { [weak self] image in
            if let cachedImage = image { // image is already cached
                print("🎾 image is already cached")
                self?.set(image: cachedImage, options: options)
            } else {
                SimpleCache.downloadImage(from: url, presetKey: key) { image in
                   print("🎾 image is downloaded and cached")
                    self?.set(image: image, options: options)
                }
            }
        }
    }
    
    private func set(image: UIImage?, options: [SimpleCacheOptions]?) {
        guard let options = options else {
            self.image = image
            return
        }
        options.forEach {
            switch $0 {
            case .fade(let duration):
                UIView.transition(with: self, duration: duration, options: [.transitionCrossDissolve], animations: {
                    self.image = image
                }, completion: nil)
            }
        }
    }
}
