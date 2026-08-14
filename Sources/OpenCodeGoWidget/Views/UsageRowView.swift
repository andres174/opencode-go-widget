import SwiftUI

struct UsageRowView: View {
    let title: String
    let window: UsageWindow

    private let resetFormatter = ResetDateFormatter()

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
            if window.resetsAt != nil {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(resetText(relativeTo: context.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .help(exactResetText ?? "")
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

    private func resetText(relativeTo now: Date) -> String {
        resetFormatter.friendlyResetText(resetsAt: window.resetsAt, relativeTo: now)
            ?? window.resetsAt
            ?? ""
    }

    private var exactResetText: String? {
        resetFormatter.exactResetText(resetsAt: window.resetsAt)
    }

    private var accessibilityLabel: String {
        if let exactResetText {
            return "\(title), \(exactResetText)"
        }
        return title
    }
}
