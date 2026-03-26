//
//  DoorRowView.swift
//

import DomainKit
import SwiftUI

struct DoorRowView: View {
    let door: Door

    var body: some View {
        HStack(spacing: Layout.hStackSpacing) {
            VStack(alignment: .leading, spacing: Layout.innerSpacing) {
                Text(door.name)
                    .font(.headline)
                if let address = door.address {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if let battery = door.battery {
                BatteryBadge(level: battery)
                    .fixedSize()
            }
        }
        .padding(.vertical, Layout.verticalPadding)
        .accessibilityLabel("Door \(door.name)\(door.battery.map { ", battery \($0)%" } ?? "")")
    }
}

// MARK: - Layout

extension DoorRowView {
    enum Layout {
        static let innerSpacing: CGFloat = 4
        static let verticalPadding: CGFloat = 6
        static let hStackSpacing: CGFloat = 8
    }
}

// MARK: - BatteryBadge

private struct BatteryBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: Layout.labelSpacing) {
            Image(systemName: batteryIcon)
            Text("\(level)%")
                .monospacedDigit()
                .frame(width: Layout.percentageWidth, alignment: .trailing)
        }
        .font(.caption2)
        .foregroundStyle(color)
    }

    private var batteryIcon: String {
        switch level {
        case 0 ... Layout.lowThreshold: Icons.low
        case (Layout.lowThreshold + 1) ... Layout.mediumThreshold: Icons.medium
        case (Layout.mediumThreshold + 1) ... Layout.highThreshold: Icons.high
        default: Icons.full
        }
    }

    private var color: Color {
        if level <= Layout.lowThreshold { return .red }
        if level <= Layout.mediumThreshold { return .orange }
        return .green
    }
}

extension BatteryBadge {
    enum Layout {
        static let lowThreshold = 20
        static let mediumThreshold = 50
        static let highThreshold = 75
        static let percentageWidth: CGFloat = 36
        static let labelSpacing: CGFloat = 2
    }

    enum Icons {
        static let low = "battery.0"
        static let medium = "battery.25"
        static let high = "battery.50"
        static let full = "battery.100"
    }
}

// MARK: - Preview

#Preview("Door Row") {
    List {
        DoorRowView(door: Door(
            id: 1,
            name: "Main Entrance",
            serial: nil,
            lockMac: nil,
            address: "123 Main St, Suite 400",
            latitude: nil,
            longitude: nil,
            battery: 82
        ))
        DoorRowView(door: Door(
            id: 2,
            name: "Back Door",
            serial: nil,
            lockMac: nil,
            address: nil,
            latitude: nil,
            longitude: nil,
            battery: 12
        ))
        DoorRowView(door: Door(
            id: 3,
            name: "Side Gate",
            serial: nil,
            lockMac: nil,
            address: nil,
            latitude: nil,
            longitude: nil,
            battery: nil
        ))
    }
    .listStyle(.plain)
}
