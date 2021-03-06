import XCTest
@testable import SimpleCache

struct SampleEncodable: Codable, Equatable, SimplyCacheIdentifiable {
    let id: UUID
    
    var cacheItemId: String {
        return id.uuidString
    }
}

struct OrderedEncodable: Codable, Equatable, SimplyCacheIdentifiable {
    let order: Int
    
    var cacheItemId: String {
        return String(order)
    }
}


final class SimpleCacheTests: XCTestCase {
    
    // MARK: - Image Cache Tests
    
    func testSaveAndRetrieveImage() {
        let key = randomKey()
        SimpleCache.save(image: SimpleCacheTests.getTestImageData(), for: key)
        let image = SimpleCache.object(for: key)
        XCTAssertNotNil(image)
    }
    
    func testUIImageSaveImage() {
        let key = randomKey()
        SimpleCacheTests.getTestImageData().save(for: key)
        let image = SimpleCache.object(for: key)
        XCTAssertNotNil(image)
    }
    
    func testSaveImageFromURL() {
        let key = CacheKey(url: URL(string: "https://via.placeholder.com/300.png/09f/fff")!)
        SimpleCache.save(image: SimpleCacheTests.getTestImageData(), for: key)
        let image = SimpleCache.object(for: key)
        XCTAssertNotNil(image)
    }
    
    func testDownloadAndCacheImage() {
        let exp = XCTestExpectation(description: "download-image")
        let url = URL(string: "https://via.placeholder.com/300.png/09f/fff%20%20C/O%20h")!
        SimpleCache.downloadImage(from: url, presetKey: nil) { (image) in
            guard let image = image else {
                XCTFail("Image was not downloaded")
                return
            }
            let key = CacheKey(url: url)
            guard let cachedImage = SimpleCache.object(for: key) else {
                XCTFail("Downloaded image was not cached")
                return
            }
            XCTAssert(cachedImage.hashValue == image.hashValue, "Cached image is not the same as the downloaded image")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }
    
    // MARK: - Encodable Tests
    
    func testSaveSingleCodeable() {
        let item = SampleEncodable(id: UUID())
        let name = "samples/\(UUID().uuidString).json"
        SimpleCache.save(item, for: name) {
            XCTAssert($0, "Codable was not saved")
            let cachedItem = SimpleCache.get(for: name, as: SampleEncodable.self)
                   XCTAssertNotNil(cachedItem, "Could not find cached item")
                   XCTAssertEqual(item, cachedItem)
        }
    }
    
    func testSaveMultipleCodeables() {
        let samples = getSampleList()
        let name = "samples/\(UUID()).json"
        let exp = XCTestExpectation()
        SimpleCache.save(samples, for: name) {
            XCTAssert($0, "Codables were not saved")
            let cachedItems = SimpleCache.get(for: name, as: [SampleEncodable].self)
            XCTAssertNotNil(cachedItems, "Could not find cached items")
            XCTAssertEqual(samples, cachedItems)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4.0)
    }
    
    func testInsertCodables() {
        let samples = getSampleList()
        let name = "samples/\(UUID()).json"
        let exp = XCTestExpectation()
        var insertSamples = getSampleList()
        SimpleCache.save(samples, for: name) {
            XCTAssert($0)
            SimpleCache.insert(insertSamples, for: name) {
                XCTAssert($0)
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 4.0)
        let getAllSamples = SimpleCache.get(for: name, as: [SampleEncodable].self)
        insertSamples.append(contentsOf: samples)
        XCTAssertEqual(insertSamples, getAllSamples)
    }
    
    func testAppendCodables() {
        var samples = getSampleList()
        let name = "samples/\(UUID()).json"
        let exp = XCTestExpectation()
        let insertSamples = self.getSampleList()
        SimpleCache.save(samples, for: name) {
            XCTAssert($0)
            SimpleCache.append(insertSamples, for: name) {
                XCTAssert($0)
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 4.0)
        let getAllSamples = SimpleCache.get(for: name, as: [SampleEncodable].self)
        samples.append(contentsOf: insertSamples)
        XCTAssertEqual(samples, getAllSamples)
    }
    
    func testDeleteCodable() {
        let samples = getSampleList()
        let name = "samples/\(UUID()).json"
        let deleted = samples[5]
        let after = samples[6]
        let exp = XCTestExpectation()
        SimpleCache.save(samples, for: name) {
            XCTAssert($0)
            SimpleCache.remove(deleted.cacheItemId, of: SampleEncodable.self, for: name) { _ in
                guard let retrieved = SimpleCache.get(for: name, as: [SampleEncodable].self) else {
                    XCTFail("Not retrieved")
                    return
                }
                XCTAssert(retrieved.count+1 == samples.count)
                XCTAssertFalse(retrieved.contains(where: {$0.id == deleted.id}))
                XCTAssertEqual(after, retrieved[5])
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 4.0)
    }
    
    func testReplaceCodable() {
        let samples = getSampleList()
        let name = "samples/\(UUID()).json"
        let exp = XCTestExpectation()
        SimpleCache.save(samples, for: name) {
            XCTAssert($0)
            let deleted = samples[5]
            let newId = UUID()
            SimpleCache.replace(deleted.cacheItemId, with: SampleEncodable(id: newId), for: name) { _ in
                guard let retrieved = SimpleCache.get(for: name, as: [SampleEncodable].self) else {
                    XCTFail("Not retrieved")
                    return
                }
                XCTAssert(retrieved.contains(where: {$0.id == newId}))
                XCTAssertFalse(retrieved.contains(where: {$0.id == deleted.id}))
                XCTAssert(retrieved.count == samples.count)
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 4.0)
    }

    func testEmptyInsert() {
        let samples = getSampleList()
        let name = "samples/\(UUID()).json"
        let exp = XCTestExpectation()
        SimpleCache.insert(samples, for: name) {
            XCTAssert($0)
            let retrieved = SimpleCache.get(for: name, as: [SampleEncodable].self)
            XCTAssertEqual(samples, retrieved)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4.0)
    }

    func testEmptyAdd() {
        let samples = getSampleList()
        let name = "samples/\(UUID()).json"
        let exp = XCTestExpectation()
        SimpleCache.insert(samples, for: name) {
            XCTAssert($0)
            let retrieved = SimpleCache.get(for: name, as: [SampleEncodable].self)
            XCTAssertEqual(samples, retrieved)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4.0)
    }

    func testComplexOrdering() {
        var loaded: [OrderedEncodable] = []
        for i in 1...10 {
            loaded.append(OrderedEncodable(order: i))
        }
        let path = "samples/\(UUID().uuidString).json"
        let exp = XCTestExpectation()

        SimpleCache.append(loaded, for: path) { _ in
            let check1 = SimpleCache.get(for: path, as: [OrderedEncodable].self)
            XCTAssertEqual(check1, loaded)
            SimpleCache.append([OrderedEncodable(order: 11)], for:  path) { _ in
                SimpleCache.insert([OrderedEncodable(order: 0)].reversed(), for:  path) { _ in
                    SimpleCache.insert([OrderedEncodable(order: -1), OrderedEncodable(order: -2), OrderedEncodable(order: -3)].reversed(), for:  path) { _ in
                        let check2 = SimpleCache.get(for: path, as: [OrderedEncodable].self)
                        var verification: [OrderedEncodable] = []
                        for i in -3...11 {
                            verification.append(OrderedEncodable(order: i))
                        }
                        XCTAssertEqual(verification, check2)
                        exp.fulfill()
                    }
                }
            }
        }
        wait(for: [exp], timeout: 4.0)
    }


    func testDeleteDirectory() {
        let path = "samples/\(UUID().uuidString).json"
        let samples = getSampleList()
        let exp = XCTestExpectation()
        SimpleCache.insert(samples, for: path) { _ in
            let check1 = SimpleCache.get(for: path, as: [SampleEncodable].self)
            XCTAssertEqual(check1, samples)
            XCTAssert(SimpleCache.removeAll(in: path))
            XCTAssert(SimpleCache.get(for: path, as: [SampleEncodable].self)?.isEmpty ?? true)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4.0)
    }

    func testCacheKeyMatching() {
        let url1String = "https://ui-avatars.com/api/?background=43adf0&color=fff&name=Aaron+Satterfield&size=512"
        let url2String = "https://ui-avatars.com/api/?background=5d4298&color=fff&name=Elmer+Morales&size=512"

        guard let url1 = URL(string: url1String), let url2 = URL(string: url2String) else {
            XCTFail("Urls are invalid")
            return
        }

        let key1 = CacheKey(url: url1)
        let key2 = CacheKey(url: url2)

        XCTAssertNotEqual(key1, key2)
    }
    
    private func getSampleList(count: Int = 1000) -> [SampleEncodable] {
        return [Bool](repeating: true, count: count).map { _ in UUID() }.map { SampleEncodable(id: $0) }
    }
    

    static var allTests = [
        ("testSaveAndRetrieveImage", testSaveAndRetrieveImage),
        ("testUIImageSaveImage", testUIImageSaveImage),
        ("testSaveImageFromURL", testSaveImageFromURL),
        ("testDownloadAndCacheImage", testDownloadAndCacheImage),
        ("testSaveSingleCodeable", testSaveSingleCodeable),
        ("testSaveMultipleCodeables", testSaveMultipleCodeables),
        ("testInsertCodables", testInsertCodables),
        ("testAppendCodables", testAppendCodables),
        ("testDeleteCodable", testDeleteCodable),
        ("testReplaceCodable", testReplaceCodable),
        ("testEmptyInsert", testEmptyInsert),
        ("testEmptyAdd", testEmptyAdd),
        ("testComplexOrdering", testComplexOrdering),
        ("testDeleteDirectory", testDeleteDirectory)
    ]
}

// MARK: -
extension SimpleCacheTests {
    
    // MARK: Helpers
    
    func randomKey() -> CacheKey {
        return CacheKey(path: UUID().uuidString)
    }
    
    static func getTestImageData(imageSize: CGSize = CGSize(width: 1000, height: 1000)) -> UIImage {
        let size = imageSize
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        UIGraphicsGetCurrentContext()?.setFillColor(UIColor.red.cgColor)
        UIGraphicsGetCurrentContext()?.fill(CGRect(origin: .zero, size: size))
        
        // add a timestamp to the image
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        NSString(string: formatter.string(from: Date())).draw(at: .zero, withAttributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 16.0)])
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    
}
