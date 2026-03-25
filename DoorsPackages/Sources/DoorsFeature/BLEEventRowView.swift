import DomainKit
import SwiftUI

public struct BLEEventRowView: View {
    let frame: BLEFrame

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(frame.eventType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
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
            Text(String(format: "0x%02X", frame.logCode))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(frame.eventType.rawValue) at \(frame.timestamp.formatted())")
    }
}
