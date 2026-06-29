import XCTest
// Hadiths.swift compiled into this test target.

final class HadithTests: XCTestCase {
    func testLibraryNonEmptyAndUnique() {
        XCTAssertFalse(HadithLibrary.all.isEmpty)
        let ids = HadithLibrary.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testTodayReturnsValidNarration() {
        let h = HadithLibrary.today()
        XCTAssertTrue(HadithLibrary.all.contains(h))
        XCTAssertFalse(h.text.isEmpty)
        XCTAssertFalse(h.collection.isEmpty)
        XCTAssertFalse(h.reference.isEmpty)
    }

    func testCitationFormat() {
        let h = HadithLibrary.all[0]
        XCTAssertEqual(h.citation, "\(h.collection) \(h.reference)")
    }

    func testCollectionsHaveContent() {
        for c in HadithLibrary.collections {
            XCTAssertFalse(HadithLibrary.inCollection(c).isEmpty, "no hadith in \(c)")
        }
    }

    func testFreeVsPremiumCollections() {
        XCTAssertTrue(HadithLibrary.isFree("Sahih al-Bukhari"))
        XCTAssertTrue(HadithLibrary.isFree("Sahih Muslim"))
        XCTAssertFalse(HadithLibrary.isFree("Jami' at-Tirmidhi"))
    }
}
