import Foundation
import Combine
import UserNotifications

struct Devotional: Identifiable, Hashable {
    let id: Int
    let verse: String
    let reference: String
    let reflection: String
}

enum DevotionalLibrary {
    /// A small bundled set that rotates daily — fully offline. Pro plans/audio are
    /// a content/Remote upgrade.
    static let all: [Devotional] = [
        .init(id: 0, verse: "I can do all things through Christ who strengthens me.", reference: "Philippians 4:13", reflection: "Whatever you face today, you don't face it alone or in your own strength."),
        .init(id: 1, verse: "The Lord is my shepherd; I shall not want.", reference: "Psalm 23:1", reflection: "Rest in the assurance that your needs are seen and provided for."),
        .init(id: 2, verse: "Trust in the Lord with all your heart, and lean not on your own understanding.", reference: "Proverbs 3:5", reflection: "Release the need to have every answer; trust the One who does."),
        .init(id: 3, verse: "Be still, and know that I am God.", reference: "Psalm 46:10", reflection: "Stillness is not weakness — it's where you remember who holds it all."),
        .init(id: 4, verse: "And we know that all things work together for good to those who love God.", reference: "Romans 8:28", reflection: "Even the hard chapters are being woven into something good."),
        .init(id: 5, verse: "Cast all your anxiety on him because he cares for you.", reference: "1 Peter 5:7", reflection: "Your worries are not a burden to God; bring them honestly."),
        .init(id: 6, verse: "The Lord is near to all who call on him.", reference: "Psalm 145:18", reflection: "No prayer is too small or too late to reach a near God."),
    ]

    static func today() -> Devotional {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return all[day % all.count]
    }
}

/// Saved favorites + a daily reminder. Free tier saves a few; Pro unlimited.
final class DevotionalStore: ObservableObject {
    @Published private(set) var favorites: [Int] = []
    static let freeFavorites = 3
    private let key = "devo.favorites.v1"

    init() { load() }

    func isFavorite(_ d: Devotional) -> Bool { favorites.contains(d.id) }
    func reachedFreeLimit(isSubscribed: Bool) -> Bool { !isSubscribed && favorites.count >= Self.freeFavorites }

    func toggle(_ d: Devotional) {
        if let i = favorites.firstIndex(of: d.id) { favorites.remove(at: i) } else { favorites.append(d.id) }
        save()
    }

    func scheduleDailyReminder(hour: Int = 8) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Today's Devotional"
            content.body = "A verse and a moment of reflection is ready for you."
            content.sound = .default
            var comps = DateComponents(); comps.hour = hour
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "daily-devo", content: content, trigger: trigger))
        }
    }

    private func load() {
        favorites = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
    }
    private func save() { UserDefaults.standard.set(favorites, forKey: key) }
}
