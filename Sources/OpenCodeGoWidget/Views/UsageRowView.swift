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
            progressBar
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

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: fillWidth(in: geometry.size.width))
            }
        }
        .frame(height: 7)
        .accessibilityHidden(true)
    }

    private var color: Color {
        UsageTone.color(for: window.validatedPercent)
    }

    private func fillWidth(in total: CGFloat) -> CGFloat {
        let ratio = window.validatedPercent / 100
        guard ratio > 0 else { return 0 }
        return max(total * ratio, 6)
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
