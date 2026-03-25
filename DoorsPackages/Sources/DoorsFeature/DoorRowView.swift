import DomainKit
import SwiftUI

public struct DoorRowView: View {
    let door: Door

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(door.name)
                .font(.headline)
            if let description = door.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Door: \(door.name)")
    }
}
