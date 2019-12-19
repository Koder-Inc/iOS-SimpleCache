import XCTest
@testable import SimpleCache

@available(iOS 13.0, *)
final class SimpleCacheTests: XCTestCase {
    
    let testImage = UIImage(systemName: "person.circle.fill")!
    
    func randomKey() -> CacheKey {
        return CacheKey(id: UUID().uuidString)
    }
    
    func testSaveAndRetrieve() {
        let key = randomKey()
        SimpleCache.save(image: testImage, for: key)
        let image = SimpleCache.object(for: key)
        XCTAssertNotNil(image)
    }
    
    func testUIImageSave() {
        let key = randomKey()
        testImage.save(for: key)
        let image = SimpleCache.object(for: key)
        XCTAssertNotNil(image)
    }

    static var allTests = [
        ("testSaveAndRetrieve", testSaveAndRetrieve),
    ]
}
