import SwiftUI

@main
struct OpenCodeGoWidgetApp: App {
    @StateObject private var viewModel: UsageViewModel
    @StateObject private var preferences: PreferencesStore

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel, preferences: preferences)
        } label: {
            if let percent = viewModel.summaryPercent {
                Text("\(percent, specifier: "%.0f")%")
                    .monospacedDigit()
                    .foregroundStyle(UsageTone.color(for: percent))
                    .accessibilityLabel("Usage: \(Int(percent.rounded())) percent")
            } else if let symbol = viewModel.summarySymbol {
                Image(systemName: symbol)
            } else {
                Image(systemName: "chart.bar.fill")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel, preferences: preferences, isPresented: .constant(true), isEmbedded: false)
        }
    }

    init() {
        let preferences = PreferencesStore()
        _preferences = StateObject(wrappedValue: preferences)
        _viewModel = StateObject(wrappedValue: UsageViewModel(preferences: preferences))
        viewModel.start()
        viewModel.requestNotifications()
    }
}
