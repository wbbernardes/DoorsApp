//
//  EventRowView.swift
//

import DomainKit
import SwiftUI

struct EventRowView: View {
    let event: DoorEvent

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.innerSpacing) {
            HStack {
                Image(systemName: iconName(for: event.logType))
                    .foregroundStyle(iconColor(for: event.logType))
                Text(event.logType.formatted)
                    .font(.headline)
                Spacer()
                Text(event.eventTimestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !event.additionalData.isEmpty {
                Text(event.additionalData.map { "\($0.parameterName): \($0.parsedValue ?? $0.hexValue ?? "-")" }
                    .joined(separator: Layout.parameterSeparator))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(Layout.parameterLineLimit)
            }
        }
        .padding(.vertical, Layout.verticalPadding)
        .accessibilityLabel("\(event.logType.formatted) at \(event.eventTimestamp.formatted())")
    }

    private func iconName(for logType: String) -> String {
        if logType.contains("OPEN") { return Icons.open }
        if logType.contains("CLOSE") { return Icons.close }
        if logType.contains("UNLOCK") { return Icons.unlock }
        if logType.contains("BATTERY") { return Icons.battery }
        if logType.contains("ERROR") { return Icons.error }
        return Icons.fallback
    }

    private func iconColor(for logType: String) -> Color {
        if logType.contains("DENIED") { return .red }
        if logType.contains("ERROR") { return .orange }
        if logType.contains("UNLOCK") { return .green }
        return .secondary
    }
}

// MARK: - Layout & Constants

extension EventRowView {
    enum Layout {
        static let innerSpacing: CGFloat = 4
        static let verticalPadding: CGFloat = 4
        static let parameterLineLimit = 2
        static let parameterSeparator = "  ·  "
    }

    enum Icons {
        static let open = "door.left.hand.open"
        static let close = "door.left.hand.closed"
        static let unlock = "lock.open"
        static let battery = "battery.25"
        static let error = "exclamationmark.triangle"
        static let fallback = "clock"
    }
}

// MARK: - Helpers

private extension String {
    var formatted: String {
        replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Preview

#Preview("Event Row") {
    List {
        EventRowView(event: DoorEvent(
            id: 1,
            logType: "DOOR_OPEN",
            eventTimestamp: Date().addingTimeInterval(-120),
            additionalData: [EventParameter(parameterName: "user", hexValue: nil, parsedValue: "John")]
        ))
        EventRowView(event: DoorEvent(
            id: 2,
            logType: "UNLOCK_DENIED",
            eventTimestamp: Date().addingTimeInterval(-600),
            additionalData: []
        ))
        EventRowView(event: DoorEvent(
            id: 3,
            logType: "BATTERY_LOW",
            eventTimestamp: Date().addingTimeInterval(-3600),
            additionalData: [EventParameter(parameterName: "level", hexValue: nil, parsedValue: "12")]
        ))
    }
    .listStyle(.plain)
}
