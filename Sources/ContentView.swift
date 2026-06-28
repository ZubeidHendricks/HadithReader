import SwiftUI
import AppFactoryKit

// Daily Devotional & Bible — a verse + reflection each day, save favorites, and a
// daily reminder. Fully on-device. Pro unlocks unlimited favorites (and is the
// seam for full reading plans + audio).
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    @StateObject private var store = DevotionalStore()

    private let today = DevotionalLibrary.today()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    card(today)
                    if !store.favorites.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Saved").font(.headline)
                            ForEach(DevotionalLibrary.all.filter { store.favorites.contains($0.id) }) { d in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(d.verse).font(.callout)
                                    Text(d.reference).font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Today")
        }
        .task { store.scheduleDailyReminder() }
    }

    private func card(_ d: Devotional) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill").font(.system(size: 36)).foregroundStyle(.orange)
            Text(d.verse).font(.title3.weight(.semibold)).multilineTextAlignment(.center)
            Text(d.reference).font(.subheadline).foregroundStyle(.secondary)
            Divider()
            Text(d.reflection).font(.body).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button {
                if store.isFavorite(d) { store.toggle(d) }
                else if store.reachedFreeLimit(isSubscribed: factory.subscriptions.isSubscribed) {
                    factory.presentPaywall(placement: "favorites_limit")
                } else { store.toggle(d) }
            } label: {
                Label(store.isFavorite(d) ? "Saved" : "Save", systemImage: store.isFavorite(d) ? "heart.fill" : "heart")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent).tint(.orange)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.orange.opacity(0.10)))
    }
}
