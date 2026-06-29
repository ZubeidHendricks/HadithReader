import SwiftUI
import AppFactoryKit

// Hadith Reader — daily hadith + browse the major collections. Payments use
// native StoreKit 2 (no third-party SDK). Products read from App Store Connect.
private enum Product {
    static let yearly = "hadith_pro_yearly"
    static let weekly = "hadith_pro_weekly"
}

@MainActor
enum HadithFactory {
    static func make() -> AppFactory {
        let config = AppFactoryConfiguration(
            appName: "Hadith Reader",
            purchaseProvider: StoreKit2PurchaseProvider(productIDs: [Product.yearly, Product.weekly]),
            onboarding: OnboardingConfiguration(
                slides: [
                    .init(systemImage: "book.closed.fill",
                          title: "Hadith of the Day",
                          message: "Read an authentic narration each day, with its source and narrator."),
                    .init(systemImage: "books.vertical.fill",
                          title: "The Major Collections",
                          message: "Browse Sahih al-Bukhari, Sahih Muslim, Abu Dawud, at-Tirmidhi and more."),
                    .init(systemImage: "bookmark.fill",
                          title: "Save & Reflect",
                          message: "Bookmark the narrations that move you and get a gentle daily reminder.")
                ],
                presentsPaywallOnFinish: true,
                accent: .green
            ),
            paywall: PaywallConfiguration(
                headline: "Unlock Hadith Reader Pro",
                subheadline: "Full access to every collection.",
                benefits: [
                    .init(systemImage: "books.vertical.fill", title: "All collections", subtitle: "Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah"),
                    .init(systemImage: "bookmark.fill", title: "Unlimited bookmarks"),
                    .init(systemImage: "magnifyingglass", title: "Search every narration"),
                    .init(systemImage: "nosign", title: "No ads")
                ],
                productIDs: [Product.yearly, Product.weekly],
                highlightedProductID: Product.yearly,
                ctaTitle: "Continue",
                dismissButtonDelay: 4,
                isDismissable: true,
                termsURL: URL(string: "https://zubeidhendricks.github.io/HadithReader/terms.html"),
                privacyURL: URL(string: "https://zubeidhendricks.github.io/HadithReader/privacy.html"),
                style: PaywallStyle(accent: .green, heroSystemImage: "book.closed.fill")
            )
        )
        return AppFactory(config)
    }
}

@main
struct HadithReaderApp: App {
    @StateObject private var factory = HadithFactory.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFactoryRoot(factory)
                .tint(.green)
        }
    }
}
