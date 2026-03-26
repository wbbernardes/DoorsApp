//
//  PrimaryActionButton.swift
//

import SwiftUI

public struct PrimaryActionButton: View {
    let label: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    public init(
        _ label: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    Text(label)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.height)
        }
        .glassEffect(in: .capsule)
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? Layout.disabledOpacity : 1.0)
    }
}

extension PrimaryActionButton {
    enum Layout {
        static let height: CGFloat = 50
        static let disabledOpacity: Double = 0.4
    }
}
