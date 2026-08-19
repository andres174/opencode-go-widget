import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var preferences: PreferencesStore
    @State private var showSettings = false
    @State private var isHistoryExpanded = false
    @State private var isHistoryHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showSettings {
                SettingsView(
                    viewModel: viewModel,
                    preferences: preferences,
                    isPresented: $showSettings,
                    isEmbedded: true
                )
            } else {
                header
                Divider()
                content
                Divider()
                footer
            }
        }
        .padding(14)
        .frame(width: 330)
    }

    private var header: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(viewModel.summaryPercent.map(UsageTone.color(for:)) ?? Color.accentColor)
                .accessibilityHidden(true)
            Text("OpenCode Go").font(.headline)
            Spacer()
            if viewModel.latestUsage == nil, case .loading = viewModel.state {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Loading usage")
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let response = viewModel.latestUsage {
            loadedContent(response)
            statusBanner
        } else {
            placeholderContent
        }
    }

    @ViewBuilder private func loadedContent(_ response: UsageResponse) -> some View {
        UsageRowView(title: "Rolling", window: response.usage.rolling)
        UsageRowView(title: "Weekly", window: response.usage.weekly)
        UsageRowView(title: "Monthly", window: response.usage.monthly)
        if viewModel.history.snapshots.count >= 2 {
            Divider()
            historySection
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHistoryExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("History")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isHistoryExpanded ? 90 : 0))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
                .background(isHistoryHovered ? Color.primary.opacity(0.06) : Color.clear)
                .cornerRadius(6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHistoryHovered = $0 }
            .accessibilityLabel("History")
            .accessibilityValue(isHistoryExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint("Shows usage history chart")

            if isHistoryExpanded {
                HistoryChartView(snapshots: viewModel.history.snapshots, preferences: preferences)
                    .padding(.top, 2)
            }
        }
    }

    @ViewBuilder private var statusBanner: some View {
        switch viewModel.state {
        case .failed(let message):
            banner(message: message, systemImage: "exclamationmark.triangle", tint: .red, accessibilityPrefix: "Error")
        case .offline(let message):
            banner(message: message, systemImage: "wifi.slash", tint: .orange, accessibilityPrefix: "Offline")
        default:
            EmptyView()
        }
    }

    private func banner(message: String, systemImage: String, tint: Color, accessibilityPrefix: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Label(message, systemImage: systemImage)
                .foregroundStyle(tint)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Retry") { Task { await viewModel.refresh() } }
                .controlSize(.small)
                .disabled(viewModel.isRefreshing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(accessibilityPrefix): \(message)")
    }

    @ViewBuilder private var placeholderContent: some View {
        switch viewModel.state {
        case .needsAPIKey:
            Text("Set your API key to check usage.")
                .foregroundStyle(.secondary)
            Button("Set API key") { showSettings = true }
        case .loading, .idle, .loaded:
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
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Label {
                        Text("Refresh")
                    } icon: {
                        if viewModel.isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .disabled(viewModel.isRefreshing)
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .controlSize(.small)
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
