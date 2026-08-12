import SwiftUI

@main
struct OpenCodeGoWidgetApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            if let percent = viewModel.summaryPercent {
                Text("\(percent, specifier: "%.0f")%")
                    .monospacedDigit()
            } else {
                Image(systemName: "chart.bar.fill")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel, isPresented: .constant(true))
        }
    }

    init() {
        viewModel.start()
    }
}
