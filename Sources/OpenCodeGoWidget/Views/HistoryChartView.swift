import Charts
import SwiftUI

struct HistoryChartView: View {
    let snapshots: [UsageSnapshot]
    @ObservedObject var preferences: PreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(preferences.menuBarMetric.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart {
                ForEach(snapshots) { snapshot in
                    AreaMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Percent", percent(snapshot))
                    )
                    .foregroundStyle(tone.opacity(0.18))
                    LineMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Percent", percent(snapshot))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tone)
                    PointMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Percent", percent(snapshot))
                    )
                    .symbolSize(8)
                    .foregroundStyle(tone)
                }
                RuleMark(y: .value("100%", 100))
                    .foregroundStyle(.red.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 110)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Usage history chart for \(preferences.menuBarMetric.title.lowercased()) usage")
    }

    private var tone: Color {
        UsageTone.color(for: snapshots.last.map(percent) ?? 0)
    }

    private func percent(_ snapshot: UsageSnapshot) -> Double {
        switch preferences.menuBarMetric {
        case .rolling: return snapshot.rollingPercent
        case .weekly: return snapshot.weeklyPercent
        case .monthly: return snapshot.monthlyPercent
        }
    }
}
