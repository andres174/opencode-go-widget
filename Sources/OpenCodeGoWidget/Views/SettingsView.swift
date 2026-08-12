import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    @Binding var isPresented: Bool
    @State private var apiKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OpenCode Go")
                .font(.title2.bold())
            Text("La API key se guarda de forma segura en el Keychain de macOS.")
                .font(.callout)
                .foregroundStyle(.secondary)
            SecureField("OPENCODE_API_KEY", text: $apiKey)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Guardar") {
                    viewModel.saveAPIKey(apiKey)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                Spacer()
                Button("Cancelar") { isPresented = false }
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}
