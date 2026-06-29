import SwiftUI
import AppFactoryKit

struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    @StateObject private var store = HadithStore()

    var body: some View {
        TabView {
            TodayView(store: store).tabItem { Label("Today", systemImage: "sun.max") }
            CollectionsView(store: store).tabItem { Label("Collections", systemImage: "books.vertical") }
            SearchView(store: store).tabItem { Label("Search", systemImage: "magnifyingglass") }
            BookmarksView(store: store).tabItem { Label("Saved", systemImage: "bookmark") }
        }
        .task { store.scheduleDailyReminder() }
    }
}

// MARK: - Today

private struct TodayView: View {
    @ObservedObject var store: HadithStore
    @State private var today: Hadith?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let today {
                    HadithCard(hadith: today, store: store, big: true).padding(20)
                } else {
                    ProgressView().padding(.top, 80)
                }
            }
            .navigationTitle("Today")
        }
        .task {
            today = await Task.detached { HadithLibrary.today() }.value
        }
    }
}

// MARK: - Collections

private struct CollectionsView: View {
    @EnvironmentObject private var factory: AppFactory
    @ObservedObject var store: HadithStore

    var body: some View {
        NavigationStack {
            List(HadithLibrary.collections) { c in
                if c.isFree || factory.subscriptions.isSubscribed {
                    NavigationLink(c.name) { CollectionDetail(collection: c, store: store) }
                } else {
                    Button { factory.presentPaywall(placement: "collection_\(c.file)") } label: {
                        HStack { Text(c.name); Spacer(); Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle("Collections")
        }
    }
}

private struct CollectionDetail: View {
    let collection: HadithLibrary.Collection
    @ObservedObject var store: HadithStore
    @State private var items: [Hadith] = []
    @State private var loading = true

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading \(collection.name)…")
            } else {
                List(items) { h in
                    HadithRow(hadith: h, store: store)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            items = await Task.detached { HadithLibrary.load(collection) }.value
            loading = false
        }
    }
}

// MARK: - Bookmarks

private struct BookmarksView: View {
    @ObservedObject var store: HadithStore

    var body: some View {
        NavigationStack {
            Group {
                if store.bookmarks.isEmpty {
                    ContentUnavailableView("No bookmarks yet", systemImage: "bookmark",
                                           description: Text("Tap the bookmark icon on any hadith to save it."))
                } else {
                    List(store.bookmarks) { HadithRow(hadith: $0, store: store) }.listStyle(.plain)
                }
            }
            .navigationTitle("Saved")
        }
    }
}

// MARK: - Search

private struct SearchView: View {
    @EnvironmentObject private var factory: AppFactory
    @ObservedObject var store: HadithStore
    @State private var query = ""
    @State private var results: [Hadith] = []
    @State private var searching = false
    @State private var didSearch = false

    var body: some View {
        NavigationStack {
            Group {
                if searching {
                    ProgressView("Searching…")
                } else if didSearch && results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else if results.isEmpty {
                    placeholder
                } else {
                    List(results) { HadithRow(hadith: $0, store: store) }.listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search the hadiths")
            .onSubmit(of: .search) { runSearch() }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.largeTitle).foregroundStyle(.secondary)
            Text(factory.subscriptions.isSubscribed
                 ? "Search across all 9 collections."
                 : "Search Sahih al-Bukhari & Muslim. Upgrade to search every collection.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal, 32)
            if !factory.subscriptions.isSubscribed {
                Button("Unlock all collections") { factory.presentPaywall(placement: "search_all") }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.top, 60)
    }

    private func runSearch() {
        let cols = factory.subscriptions.isSubscribed ? HadithLibrary.collections : HadithLibrary.freeCollectionList
        let q = query
        searching = true; didSearch = true
        Task {
            let found = await Task.detached { HadithLibrary.search(q, in: cols) }.value
            await MainActor.run { results = found; searching = false }
        }
    }
}

// MARK: - Shared views

private struct HadithRow: View {
    let hadith: Hadith
    @ObservedObject var store: HadithStore
    var body: some View {
        NavigationLink { ScrollView { HadithCard(hadith: hadith, store: store, big: true).padding(20) } } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(hadith.text).font(.callout).lineLimit(3)
                Text(hadith.citation).font(.caption).foregroundStyle(.green)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct HadithCard: View {
    let hadith: Hadith
    @ObservedObject var store: HadithStore
    @EnvironmentObject private var factory: AppFactory
    var big: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !hadith.arabic.isEmpty {
                Text(hadith.arabic)
                    .font(.system(size: big ? 24 : 20, weight: .medium))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                Divider()
            }
            Text(hadith.text).font(big ? .body : .callout)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hadith.citation).font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                    if !hadith.narrator.isEmpty {
                        Text("Narrated by \(hadith.narrator)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { toggle() } label: {
                    Image(systemName: store.isBookmarked(hadith) ? "bookmark.fill" : "bookmark").foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(.green.opacity(0.10)))
    }

    private func toggle() {
        if !store.isBookmarked(hadith) && store.reachedFreeLimit(isSubscribed: factory.subscriptions.isSubscribed) {
            factory.presentPaywall(placement: "bookmark_limit")
        } else {
            store.toggle(hadith)
        }
    }
}
