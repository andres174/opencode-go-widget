import Charts
import SwiftUI

struct HistoryChartView: View {
    let snapshots: [UsageSnapshot]
    @ObservedObject var preferences: PreferencesStore

    var body: some View {
        Chart(snapshots) { snapshot in
            LineMark(
                x: .value("Date", snapshot.date),
                y: .value("Percent", percent(snapshot))
            )
            .interpolationMethod(.catmullRom)
            PointMark(
                x: .value("Date", snapshot.date),
                y: .value("Percent", percent(snapshot))
            )
            .symbolSize(8)
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
        .accessibilityLabel("Usage history chart for \(preferences.menuBarMetric.title.lowercased()) usage")
    }

    private func percent(_ snapshot: UsageSnapshot) -> Double {
        switch preferences.menuBarMetric {
        case .rolling: return snapshot.rollingPercent
        case .weekly: return snapshot.weeklyPercent
        case .monthly: return snapshot.monthlyPercent
        }
    }
}
