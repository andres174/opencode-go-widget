import SwiftUI

struct UsageRowView: View {
    let title: String
    let window: UsageWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(window.validatedPercent, specifier: "%.0f")%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(color)
            }
            ProgressView(value: window.validatedPercent, total: 100)
                .tint(color)
            if let resetsAt = window.resetsAt {
                Text("Resets: \(formattedDate(resetsAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(Int(window.validatedPercent.rounded())) percent")
    }

    private var color: Color {
        switch window.validatedPercent {
        case 90...: return .red
        case 70..<90: return .orange
        default: return .green
        }
    }

    private var accessibilityLabel: String {
        if let resetsAt = window.resetsAt, let date = ISO8601DateFormatter().date(from: resetsAt) {
            return "\(title), resets \(date.formatted(date: .abbreviated, time: .shortened))"
        }
        return title
    }

    private func formattedDate(_ value: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: value) else { return value }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
