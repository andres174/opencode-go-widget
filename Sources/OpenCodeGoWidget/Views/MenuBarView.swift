import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: UsageViewModel
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
            SettingsView(viewModel: viewModel, isPresented: $showSettings)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(.tint)
            Text("OpenCode Go").font(.headline)
            Spacer()
            if case .loading = viewModel.state { ProgressView().controlSize(.small) }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loaded(let response):
            UsageRowView(title: "Rolling", window: response.usage.rolling)
            UsageRowView(title: "Weekly", window: response.usage.weekly)
            UsageRowView(title: "Monthly", window: response.usage.monthly)
        case .needsAPIKey:
            Text("Configura tu API key para consultar el usage.")
                .foregroundStyle(.secondary)
            Button("Configurar API key") { showSettings = true }
        case .loading, .idle:
            Text("Consultando usage...").foregroundStyle(.secondary)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
            Button("Reintentar") { Task { await viewModel.refresh() } }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let date = viewModel.lastUpdated {
                Text("Actualizado: \(date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button("Actualizar") { Task { await viewModel.refresh() } }
                Button("Configuración") { showSettings = true }
                Spacer()
                Button("Salir") { NSApplication.shared.terminate(nil) }
            }
        }
    }
}
