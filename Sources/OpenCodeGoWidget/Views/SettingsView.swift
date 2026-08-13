import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var preferences: PreferencesStore
    @Binding var isPresented: Bool
    @State private var apiKey = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OpenCode Go")
                .font(.title2.bold())
            Text("The API key is stored securely in the macOS Keychain.")
                .font(.callout)
                .foregroundStyle(.secondary)

            GroupBox("API key") {
                VStack(alignment: .leading, spacing: 10) {
                    keyStatus
                    SecureField("OPENCODE_API_KEY", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("API key")
                    HStack {
                        Button("Save") {
                            viewModel.saveAPIKey(apiKey)
                            apiKey = ""
                            isPresented = false
                        }
                        .keyboardShortcut(.defaultAction)
                        if !isAPIKeyMissing {
                            Button("Delete API key", role: .destructive) {
                                showDeleteConfirmation = true
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Preferences") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Refresh every", selection: $preferences.refreshIntervalMinutes) {
                        ForEach(PreferencesStore.intervalOptions, id: \.self) { minutes in
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }
                    Picker("Menu bar metric", selection: $preferences.menuBarMetric) {
                        ForEach(UsageMetric.allCases) { metric in
                            Text(metric.title).tag(metric)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Usage notifications") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notify when monthly usage crosses:")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Toggle("70%", isOn: $preferences.notifyAt70)
                        .onChange(of: preferences.notifyAt70) { enabled in
                            if enabled { viewModel.requestNotifications() }
                        }
                    Toggle("85%", isOn: $preferences.notifyAt85)
                        .onChange(of: preferences.notifyAt85) { enabled in
                            if enabled { viewModel.requestNotifications() }
                        }
                    Toggle("90%", isOn: $preferences.notifyAt90)
                        .onChange(of: preferences.notifyAt90) { enabled in
                            if enabled { viewModel.requestNotifications() }
                        }
                }
                .padding(.vertical, 4)
            }

            HStack {
                Spacer()
                Button("Done") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 400)
        .alert("Delete API key?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { viewModel.deleteAPIKey() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The stored API key will be removed from the Keychain.")
        }
    }

    @ViewBuilder private var keyStatus: some View {
        if isAPIKeyMissing {
            Label("No API key stored.", systemImage: "key.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Label("API key stored in Keychain.", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var isAPIKeyMissing: Bool {
        if case .needsAPIKey = viewModel.state { return true }
        return false
    }
}
