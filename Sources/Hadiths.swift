import Foundation
import Combine
import UserNotifications

struct Hadith: Identifiable, Hashable {
    let id: Int
    let text: String
    let narrator: String
    let collection: String   // e.g. "Sahih al-Bukhari"
    let reference: String    // e.g. "1"
    var citation: String { "\(collection) \(reference)" }
}

enum HadithLibrary {
    /// The collections covered. Bukhari & Muslim are free; the rest are Pro.
    static let freeCollections: Set<String> = ["Sahih al-Bukhari", "Sahih Muslim"]

    static let collections: [String] = [
        "Sahih al-Bukhari", "Sahih Muslim", "Sunan Abi Dawud", "Jami' at-Tirmidhi",
    ]

    /// A small curated set of well-known authentic narrations with standard refs.
    static let all: [Hadith] = [
        .init(id: 0, text: "Actions are judged by intentions, and every person will have only what they intended.",
              narrator: "Umar ibn al-Khattab", collection: "Sahih al-Bukhari", reference: "1"),
        .init(id: 1, text: "None of you truly believes until he loves for his brother what he loves for himself.",
              narrator: "Anas ibn Malik", collection: "Sahih al-Bukhari", reference: "13"),
        .init(id: 2, text: "Make things easy and do not make them difficult; give glad tidings and do not repel people.",
              narrator: "Anas ibn Malik", collection: "Sahih al-Bukhari", reference: "69"),
        .init(id: 3, text: "The strong person is not the one who overcomes others by strength, but the one who controls himself while in anger.",
              narrator: "Abu Hurairah", collection: "Sahih al-Bukhari", reference: "6114"),
        .init(id: 4, text: "Whoever believes in Allah and the Last Day, let him speak good or remain silent.",
              narrator: "Abu Hurairah", collection: "Sahih al-Bukhari", reference: "6018"),
        .init(id: 5, text: "The best among you are those who have the best character.",
              narrator: "Abdullah ibn Amr", collection: "Sahih al-Bukhari", reference: "6035"),
        .init(id: 6, text: "Religion is sincerity (naseehah).",
              narrator: "Tamim ad-Dari", collection: "Sahih Muslim", reference: "55"),
        .init(id: 7, text: "Cleanliness is half of faith.",
              narrator: "Abu Malik al-Ash'ari", collection: "Sahih Muslim", reference: "223"),
        .init(id: 8, text: "Allah is gentle and loves gentleness in all matters.",
              narrator: "Aishah", collection: "Sahih Muslim", reference: "2593"),
        .init(id: 9, text: "Whoever treads a path in search of knowledge, Allah makes easy for him a path to Paradise.",
              narrator: "Abu Hurairah", collection: "Sahih Muslim", reference: "2699"),
        .init(id: 10, text: "He who does not show mercy to people, Allah will not show mercy to him.",
              narrator: "Jarir ibn Abdullah", collection: "Sahih Muslim", reference: "2319"),
        .init(id: 11, text: "Whoever does not thank people has not thanked Allah.",
              narrator: "Abu Hurairah", collection: "Sunan Abi Dawud", reference: "4811"),
        .init(id: 12, text: "The most beloved deeds to Allah are those done consistently, even if small.",
              narrator: "Aishah", collection: "Sunan Abi Dawud", reference: "1370"),
        .init(id: 13, text: "Your smile for your brother is charity.",
              narrator: "Abu Dharr", collection: "Jami' at-Tirmidhi", reference: "1956"),
        .init(id: 14, text: "Fear Allah wherever you are, follow a bad deed with a good one to wipe it out, and treat people with good character.",
              narrator: "Abu Dharr", collection: "Jami' at-Tirmidhi", reference: "1987"),
    ]

    static func today() -> Hadith {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return all[day % all.count]
    }

    static func inCollection(_ name: String) -> [Hadith] {
        all.filter { $0.collection == name }
    }

    static func isFree(_ collection: String) -> Bool { freeCollections.contains(collection) }
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
