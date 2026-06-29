import XCTest
// Hadiths.swift + Resources/bukhari.json compiled into this test target.

final class HadithTests: XCTestCase {
    func testCollectionCatalog() {
        XCTAssertEqual(HadithLibrary.collections.count, 9)
        XCTAssertTrue(HadithLibrary.isFree("Sahih al-Bukhari"))
        XCTAssertTrue(HadithLibrary.isFree("Sahih Muslim"))
        XCTAssertFalse(HadithLibrary.isFree("Jami' at-Tirmidhi"))
    }

    func testFullCollectionLoads() {
        // Bukhari is the collection bundled in the test target; full edition is 7000+.
        let bukhari = HadithLibrary.load(named: "Sahih al-Bukhari")
        XCTAssertGreaterThan(bukhari.count, 5000, "expected full Bukhari; got \(bukhari.count)")
    }

    func testArabicTextPresent() {
        let bukhari = HadithLibrary.load(named: "Sahih al-Bukhari")
        let withArabic = bukhari.filter { !$0.arabic.isEmpty }
        XCTAssertGreaterThan(withArabic.count, 1000, "expected Arabic text on most entries")
    }

    func testCitationAndUniqueIDs() {
        let bukhari = HadithLibrary.load(named: "Sahih al-Bukhari")
        let h = bukhari[0]
        XCTAssertEqual(h.citation, "\(h.collection) \(h.reference)")
        let ids = bukhari.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testSearchFindsMatches() {
        let bukhari = HadithLibrary.collections.first { $0.name == "Sahih al-Bukhari" }!
        let results = HadithLibrary.search("prayer", in: [bukhari])
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy {
            $0.text.lowercased().contains("prayer") || $0.arabic.contains("prayer")
        })
    }

    func testSearchIgnoresTooShortQueries() {
        XCTAssertTrue(HadithLibrary.search("a", in: HadithLibrary.collections).isEmpty)
    }

    func testTodayDrawsFromFreeCollection() {
        let today = HadithLibrary.today()
        XCTAssertNotNil(today)
        XCTAssertTrue(HadithLibrary.isFree(today!.collection))
        XCTAssertFalse(today!.text.isEmpty)
    }
}
