//
//  BLEEventRowView.swift
//

import BLEKit
import SwiftUI

struct BLEEventRowView: View {
    let frame: BLEFrame

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.innerSpacing) {
            HStack {
                Image(systemName: iconName(for: frame.eventType))
                    .foregroundStyle(iconColor(for: frame.eventType))
                Text(frame.displayTitle)
                    .font(.headline)
                Spacer()
                Text(frame.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let value = frame.parsedValue {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(frame.displayCode)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Layout.verticalPadding)
        .accessibilityLabel("\(frame.eventType.rawValue) at \(frame.timestamp.formatted())")
    }

    private func iconName(for type: BLEEventType) -> String {
        switch type {
        case .doorOpen: Icons.open
        case .doorClose: Icons.close
        case .touchUnlock, .unlock: Icons.unlock
        case .unlockDenied: Icons.denied
        case .batteryLow: Icons.battery
        case .scheduleInit, .scheduleStart, .scheduleFinish, .scheduleCancel, .scheduleTouchCancel: Icons.schedule
        case .error, .systemError, .eepromWriteError, .eepromCrcError: Icons.error
        case .reset: Icons.reset
        default: Icons.fallback
        }
    }

    private func iconColor(for type: BLEEventType) -> Color {
        switch type {
        case .unlockDenied, .error, .systemError, .eepromWriteError, .eepromCrcError: .red
        case .batteryLow: .orange
        case .touchUnlock, .unlock: .green
        case .doorOpen: .blue
        default: .secondary
        }
    }
}

// MARK: - Layout

extension BLEEventRowView {
    enum Layout {
        static let innerSpacing: CGFloat = 4
        static let verticalPadding: CGFloat = 4
    }

    enum Icons {
        static let open = "door.left.hand.open"
        static let close = "door.left.hand.closed"
        static let unlock = "lock.open"
        static let denied = "lock.slash"
        static let battery = "battery.25"
        static let schedule = "calendar.badge.clock"
        static let error = "exclamationmark.triangle"
        static let reset = "arrow.counterclockwise"
        static let fallback = "clock"
    }
}

// MARK: - Preview

#Preview("BLE Event Row") {
    List {
        BLEEventRowView(frame: BLEFrame(
            timestamp: Date().addingTimeInterval(-90),
            logCode: 0x01,
            eventType: .doorOpen,
            parsedValue: nil
        ))
        BLEEventRowView(frame: BLEFrame(
            timestamp: Date().addingTimeInterval(-300),
            logCode: 0x50,
            eventType: .unlock,
            parsedValue: "Mode(card) PermId(42)"
        ))
        BLEEventRowView(frame: BLEFrame(
            timestamp: Date().addingTimeInterval(-900),
            logCode: 0x13,
            eventType: .batteryLow,
            parsedValue: "Level(8%)"
        ))
    }
    .listStyle(.plain)
}
