import DomainKit
import SwiftUI

public struct EventRowView: View {
    let event: DoorEvent

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                Text(event.eventType.formatted)
                    .font(.headline)
                Spacer()
                Text(event.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let params = event.parameters, !params.isEmpty {
                Text(params.map { "\($0.key): \($0.value.value)" }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(event.eventType.formatted) at \(event.timestamp.formatted())")
    }

    private var iconName: String {
        switch event.eventType {
        case _ where event.eventType.contains("OPEN"): return "door.left.hand.open"
        case _ where event.eventType.contains("CLOSE"): return "door.left.hand.closed"
        case _ where event.eventType.contains("UNLOCK"): return "lock.open"
        case _ where event.eventType.contains("BATTERY"): return "battery.25"
        default: return "clock"
        }
    }

    private var iconColor: Color {
        switch event.eventType {
        case _ where event.eventType.contains("DENIED"): return .red
        case _ where event.eventType.contains("ERROR"): return .orange
        case _ where event.eventType.contains("UNLOCK"): return .green
        default: return .secondary
        }
    }
}

private extension String {
    var formatted: String {
        replacingOccurrences(of: "_", with: " ").capitalized
    }

    func contains(_ other: String) -> Bool {
        range(of: other) != nil
    }
}
