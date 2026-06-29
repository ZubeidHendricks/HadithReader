import Foundation
import Combine
import UserNotifications

struct Hadith: Identifiable, Hashable, Codable {
    let id: Int
    let text: String
    let arabic: String
    let narrator: String
    let collection: String   // display name, e.g. "Sahih al-Bukhari"
    let reference: String    // hadith number
    var citation: String { reference.isEmpty ? collection : "\(collection) \(reference)" }
}

private final class BundleToken {}

enum HadithLibrary {
    struct Collection: Identifiable, Hashable {
        let name: String       // display name
        let file: String       // resource basename
        var id: String { file }
        var isFree: Bool { HadithLibrary.freeCollections.contains(name) }
    }

    static let freeCollections: Set<String> = ["Sahih al-Bukhari", "Sahih Muslim"]

    /// The full set of bundled collections, in display order.
    static let collections: [Collection] = [
        .init(name: "Sahih al-Bukhari", file: "bukhari"),
        .init(name: "Sahih Muslim", file: "muslim"),
        .init(name: "Sunan Abi Dawud", file: "abudawud"),
        .init(name: "Jami' at-Tirmidhi", file: "tirmidhi"),
        .init(name: "Sunan an-Nasa'i", file: "nasai"),
        .init(name: "Sunan Ibn Majah", file: "ibnmajah"),
        .init(name: "Muwatta Malik", file: "malik"),
        .init(name: "40 Hadith Nawawi", file: "nawawi"),
        .init(name: "40 Hadith Qudsi", file: "qudsi"),
    ]

    private static var cache: [String: [Hadith]] = [:]
    private static let lock = NSLock()

    /// Lazily load (and cache) one collection's hadiths from its bundled JSON.
    static func load(_ collection: Collection) -> [Hadith] {
        lock.lock(); defer { lock.unlock() }
        if let cached = cache[collection.file] { return cached }
        guard let url = Bundle(for: BundleToken.self).url(forResource: collection.file, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Hadith].self, from: data) else {
            cache[collection.file] = []
            return []
        }
        cache[collection.file] = decoded
        return decoded
    }

    static func load(named: String) -> [Hadith] {
        guard let c = collections.first(where: { $0.name == named }) else { return [] }
        return load(c)
    }

    static func isFree(_ name: String) -> Bool { freeCollections.contains(name) }

    /// Deterministic "hadith of the day" drawn from the free collections.
    static func today() -> Hadith? {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        let free = collections.filter { $0.isFree }
        // Try free collections first (rotating by day), then any collection.
        for candidate in rotated(free, by: day) + collections {
            let items = load(candidate)
            if !items.isEmpty { return items[day % items.count] }
        }
        return nil
    }

    private static func rotated(_ list: [Collection], by n: Int) -> [Collection] {
        guard !list.isEmpty else { return [] }
        let k = ((n % list.count) + list.count) % list.count
        return Array(list[k...] + list[..<k])
    }

    /// Full-text search across the given collections (English + Arabic), capped.
    static func search(_ query: String, in cols: [Collection], limit: Int = 300) -> [Hadith] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 2 else { return [] }
        var out: [Hadith] = []
        for c in cols {
            for h in load(c) where h.text.lowercased().contains(q) || h.arabic.contains(query) {
                out.append(h)
                if out.count >= limit { return out }
            }
        }
        return out
    }

    static var freeCollectionList: [Collection] { collections.filter { $0.isFree } }
}

/// Saved bookmarks (denormalized so they display without loading a collection)
/// + a daily reminder. Free tier caps bookmarks; Pro unlimited.
final class HadithStore: ObservableObject {
    @Published private(set) var bookmarks: [Hadith] = []
    static let freeBookmarks = 5
    private let key = "hadith.bookmarks.v2"

    init() { load() }

    func isBookmarked(_ h: Hadith) -> Bool { bookmarks.contains { $0.id == h.id } }
    func reachedFreeLimit(isSubscribed: Bool) -> Bool { !isSubscribed && bookmarks.count >= Self.freeBookmarks }

    func toggle(_ h: Hadith) {
        if let i = bookmarks.firstIndex(where: { $0.id == h.id }) { bookmarks.remove(at: i) }
        else { bookmarks.append(h) }
        save()
    }

    func scheduleDailyReminder(hour: Int = 9) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Hadith of the Day"
            content.body = "A new narration is ready for you to read and reflect on."
            content.sound = .default
            var comps = DateComponents(); comps.hour = hour
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "daily-hadith", content: content, trigger: trigger))
        }
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let v = try? JSONDecoder().decode([Hadith].self, from: d) else { return }
        bookmarks = v
    }
    private func save() {
        if let d = try? JSONEncoder().encode(bookmarks) { UserDefaults.standard.set(d, forKey: key) }
    }
}
