import Foundation
import Combine
import UserNotifications

struct Hadith: Identifiable, Hashable, Decodable {
    let id: Int
    let text: String
    let narrator: String
    let collection: String   // display name, e.g. "Sahih al-Bukhari"
    let reference: String    // hadith number
    var citation: String { reference.isEmpty ? collection : "\(collection) \(reference)" }
}

private final class BundleToken {}

enum HadithLibrary {
    /// Bukhari & Muslim are free; the rest unlock with Pro.
    static let freeCollections: Set<String> = ["Sahih al-Bukhari", "Sahih Muslim"]

    /// Preferred display order; only those actually present are shown.
    private static let order = [
        "Sahih al-Bukhari", "Sahih Muslim", "Sunan Abi Dawud", "Jami' at-Tirmidhi",
        "Sunan an-Nasa'i", "Sunan Ibn Majah", "Muwatta Malik",
        "40 Hadith Nawawi", "40 Hadith Qudsi",
    ]

    /// Loaded once from the bundled dataset (2,500+ narrations), with a small
    /// built-in fallback if the resource is ever missing.
    static let all: [Hadith] = load()

    static var collections: [String] {
        let present = Set(all.map(\.collection))
        let ordered = order.filter(present.contains)
        let extras = present.subtracting(order).sorted()
        return ordered + extras
    }

    static func today() -> Hadith {
        guard !all.isEmpty else { return fallback[0] }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return all[day % all.count]
    }

    static func inCollection(_ name: String) -> [Hadith] { all.filter { $0.collection == name } }
    static func isFree(_ collection: String) -> Bool { freeCollections.contains(collection) }

    private static func load() -> [Hadith] {
        if let url = Bundle(for: BundleToken.self).url(forResource: "hadiths", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Hadith].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        return fallback
    }

    /// Minimal offline fallback (used only if the bundled JSON is unavailable).
    static let fallback: [Hadith] = [
        .init(id: 0, text: "The reward of deeds depends upon the intentions, and every person will get the reward according to what he intended.",
              narrator: "'Umar ibn al-Khattab", collection: "Sahih al-Bukhari", reference: "1"),
        .init(id: 1, text: "None of you truly believes until he loves for his brother what he loves for himself.",
              narrator: "Anas ibn Malik", collection: "Sahih al-Bukhari", reference: "13"),
        .init(id: 2, text: "Religion is sincerity (naseehah).",
              narrator: "Tamim ad-Dari", collection: "Sahih Muslim", reference: "55"),
    ]
}

/// Saved bookmarks + a daily reminder. Free tier caps bookmarks; Pro unlimited.
final class HadithStore: ObservableObject {
    @Published private(set) var bookmarks: [Int] = []
    static let freeBookmarks = 5
    private let key = "hadith.bookmarks.v1"

    init() { load() }

    func isBookmarked(_ h: Hadith) -> Bool { bookmarks.contains(h.id) }
    func reachedFreeLimit(isSubscribed: Bool) -> Bool { !isSubscribed && bookmarks.count >= Self.freeBookmarks }

    func toggle(_ h: Hadith) {
        if let i = bookmarks.firstIndex(of: h.id) { bookmarks.remove(at: i) } else { bookmarks.append(h.id) }
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

    private func load() { bookmarks = UserDefaults.standard.array(forKey: key) as? [Int] ?? [] }
    private func save() { UserDefaults.standard.set(bookmarks, forKey: key) }
}
