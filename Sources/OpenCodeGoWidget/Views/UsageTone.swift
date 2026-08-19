import SwiftUI

enum UsageTone {
    static func color(for percent: Double) -> Color {
        switch percent {
        case 90...: return .red
        case 70..<90: return .orange
        default: return .green
        }
    }
}
