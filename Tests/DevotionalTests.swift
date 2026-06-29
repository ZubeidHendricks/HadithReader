import XCTest
// Devotionals.swift compiled into this test target.

final class DevotionalTests: XCTestCase {
    func testLibraryNonEmpty() {
        XCTAssertFalse(DevotionalLibrary.all.isEmpty)
    }

    func testTodayReturnsAValidEntry() {
        let today = DevotionalLibrary.today()
        XCTAssertTrue(DevotionalLibrary.all.contains(today))
        XCTAssertFalse(today.verse.isEmpty)
        XCTAssertFalse(today.reference.isEmpty)
    }

    func testEntriesHaveUniqueIDs() {
        let ids = DevotionalLibrary.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
