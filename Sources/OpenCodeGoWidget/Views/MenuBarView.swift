import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var preferences: PreferencesStore
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 330)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel, preferences: preferences, isPresented: $showSettings)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("OpenCode Go").font(.headline)
            Spacer()
            if case .loading = viewModel.state {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Loading usage")
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loaded(let response):
            UsageRowView(title: "Rolling", window: response.usage.rolling)
            UsageRowView(title: "Weekly", window: response.usage.weekly)
            UsageRowView(title: "Monthly", window: response.usage.monthly)
            if viewModel.history.snapshots.count >= 2 {
                Divider()
                DisclosureGroup("History") {
                    HistoryChartView(snapshots: viewModel.history.snapshots, preferences: preferences)
                        .padding(.top, 6)
                }
                .font(.subheadline)
            }
        case .needsAPIKey:
            Text("Set your API key to check usage.")
                .foregroundStyle(.secondary)
            Button("Set API key") { showSettings = true }
        case .loading, .idle:
            Text("Checking usage...").foregroundStyle(.secondary)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .accessibilityLabel("Error: \(message)")
            Button("Retry") { Task { await viewModel.refresh() } }
        case .offline(let message):
            Label(message, systemImage: "wifi.slash")
                .foregroundStyle(.orange)
                .accessibilityLabel("Offline: \(message)")
            Button("Retry") { Task { await viewModel.refresh() } }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let date = viewModel.lastUpdated {
                Text(updatedText(date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Last updated at \(date.formatted(date: .omitted, time: .standard))")
            }
            HStack {
                Button("Refresh") { Task { await viewModel.refresh() } }
                Button("Settings") { showSettings = true }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
    }

    private func updatedText(_ date: Date) -> String {
        switch viewModel.state {
        case .offline:
            return "Offline — updated: \(date.formatted(date: .omitted, time: .shortened))"
        case .failed, .needsAPIKey:
            return "Last updated: \(date.formatted(date: .omitted, time: .shortened))"
        default:
            return "Updated: \(date.formatted(date: .omitted, time: .shortened))"
        }
    }
}
