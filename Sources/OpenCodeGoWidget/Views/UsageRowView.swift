import SwiftUI

struct UsageRowView: View {
    let title: String
    let window: UsageWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(window.percent, specifier: "%.0f")%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(color)
            }
            ProgressView(value: min(max(window.percent, 0), 100), total: 100)
                .tint(color)
            if let resetsAt = window.resetsAt {
                Text("Renueva: \(formattedDate(resetsAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var color: Color {
        switch window.percent {
        case 90...: return .red
        case 70..<90: return .orange
        default: return .green
        }
    }

    private func formattedDate(_ value: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: value) else { return value }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
