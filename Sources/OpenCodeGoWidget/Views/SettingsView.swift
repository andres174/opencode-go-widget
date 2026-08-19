import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var preferences: PreferencesStore
    @Binding var isPresented: Bool
    var isEmbedded = false

    @State private var apiKey = ""
    @State private var showDeleteConfirmation = false
    @State private var confirmDeleteInline = false

    var body: some View {
        VStack(alignment: .leading, spacing: isEmbedded ? 12 : 16) {
            header

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
                            deleteButton
                        }
                    }
                    if isEmbedded, confirmDeleteInline {
                        inlineDeleteConfirmation
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Preferences") {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Refresh every")
                            .font(.callout)
                        Picker("Refresh every", selection: $preferences.refreshIntervalMinutes) {
                            ForEach(PreferencesStore.intervalOptions, id: \.self) { minutes in
                                Text("\(minutes)m").tag(minutes)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .accessibilityLabel("Refresh every")
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Menu bar metric")
                            .font(.callout)
                        Picker("Menu bar metric", selection: $preferences.menuBarMetric) {
                            ForEach(UsageMetric.allCases) { metric in
                                Text(metric.title).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .accessibilityLabel("Menu bar metric")
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

            if !isEmbedded {
                HStack {
                    Spacer()
                    Button("Done") { isPresented = false }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
        .padding(isEmbedded ? 0 : 24)
        .frame(width: isEmbedded ? nil : 400)
        .modifier(DeleteAPIKeyAlert(
            isEnabled: !isEmbedded,
            isPresented: $showDeleteConfirmation,
            onDelete: { viewModel.deleteAPIKey() }
        ))
    }

    @ViewBuilder private var header: some View {
        if isEmbedded {
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
                Spacer()
                Text("Settings")
                    .font(.headline)
                Spacer()
                Color.clear
                    .frame(width: 44, height: 1)
                    .accessibilityHidden(true)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("OpenCode Go")
                    .font(.title2.bold())
                Text("The API key is stored securely in the macOS Keychain.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var deleteButton: some View {
        Button("Delete API key", role: .destructive) {
            if isEmbedded {
                confirmDeleteInline = true
            } else {
                showDeleteConfirmation = true
            }
        }
    }

    private var inlineDeleteConfirmation: some View {
        HStack {
            Text("Delete the stored API key?")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Cancel") { confirmDeleteInline = false }
                .controlSize(.small)
            Button("Delete", role: .destructive) {
                viewModel.deleteAPIKey()
                confirmDeleteInline = false
                isPresented = false
            }
            .controlSize(.small)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Delete API key confirmation")
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

private struct DeleteAPIKeyAlert: ViewModifier {
    let isEnabled: Bool
    @Binding var isPresented: Bool
    let onDelete: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.alert("Delete API key?", isPresented: $isPresented) {
                Button("Delete", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The stored API key will be removed from the Keychain.")
            }
        } else {
            content
        }
    }
}
