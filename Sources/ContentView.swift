import SwiftUI
import AppFactoryKit

// Hadith Reader — daily narration, browse the collections, bookmark favorites.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    @StateObject private var store = HadithStore()

    var body: some View {
        TabView {
            todayTab.tabItem { Label("Today", systemImage: "sun.max") }
            collectionsTab.tabItem { Label("Collections", systemImage: "books.vertical") }
            bookmarksTab.tabItem { Label("Saved", systemImage: "bookmark") }
        }
        .task { store.scheduleDailyReminder() }
    }

    // MARK: Today

    private var todayTab: some View {
        NavigationStack {
            ScrollView {
                hadithCard(HadithLibrary.today(), big: true).padding(20)
            }
            .navigationTitle("Today")
        }
    }

    // MARK: Collections

    private var collectionsTab: some View {
        NavigationStack {
            List {
                ForEach(HadithLibrary.collections, id: \.self) { collection in
                    let free = HadithLibrary.isFree(collection)
                    if free || factory.subscriptions.isSubscribed {
                        NavigationLink(collection) { collectionView(collection) }
                    } else {
                        Button {
                            factory.presentPaywall(placement: "collection_\(collection)")
                        } label: {
                            HStack { Text(collection); Spacer(); Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle("Collections")
        }
    }

    private func collectionView(_ collection: String) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(HadithLibrary.inCollection(collection)) { hadithCard($0, big: false) }
            }
            .padding(16)
        }
        .navigationTitle(collection)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Bookmarks

    private var bookmarksTab: some View {
        NavigationStack {
            Group {
                let saved = HadithLibrary.all.filter { store.bookmarks.contains($0.id) }
                if saved.isEmpty {
                    ContentUnavailableView("No bookmarks yet", systemImage: "bookmark",
                                           description: Text("Tap the bookmark icon on any hadith to save it."))
                } else {
                    ScrollView { VStack(spacing: 14) { ForEach(saved) { hadithCard($0, big: false) } }.padding(16) }
                }
            }
            .navigationTitle("Saved")
        }
    }

    // MARK: Card

    private func hadithCard(_ h: Hadith, big: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("“\(h.text)”")
                .font(big ? .title3.weight(.medium) : .body)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(h.citation).font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                    Text("Narrated by \(h.narrator)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { toggleBookmark(h) } label: {
                    Image(systemName: store.isBookmarked(h) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(.green.opacity(0.10)))
    }

    private func toggleBookmark(_ h: Hadith) {
        if !store.isBookmarked(h) && store.reachedFreeLimit(isSubscribed: factory.subscriptions.isSubscribed) {
            factory.presentPaywall(placement: "bookmark_limit")
        } else {
            store.toggle(h)
        }
    }
}
