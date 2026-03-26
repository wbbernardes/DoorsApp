//
//  DoorDetailView.swift
//

import DomainKit
import SwiftUI

public struct DoorDetailView: View {
    let door: Door
    @State private var viewModel: EventsViewModel

    public init(door: Door) {
        self.door = door
        _viewModel = State(initialValue: EventsViewModel(doorId: String(door.id)))
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView(String(localized: "doors.events.loading", bundle: .module))
            } else if viewModel.showRaw {
                rawList
                    .transition(.opacity)
            } else {
                eventsList
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: Layout.toggleAnimationDuration), value: viewModel.showRaw)
        .navigationTitle(door.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                let label = viewModel.showRaw
                    ? String(localized: "doors.events.tab_parsed", bundle: .module)
                    : String(localized: "doors.events.tab_raw", bundle: .module)
                Button(label) {
                    viewModel.onToggleRaw()
                }
            }
        }
        .errorAlert(message: $viewModel.errorMessage)
        .onAppear { viewModel.onAppear() }
    }

    private var eventsList: some View {
        Group {
            if viewModel.events.isEmpty {
                ContentUnavailableView(
                    String(localized: "doors.events.empty", bundle: .module),
                    systemImage: Icons.emptyEvents
                )
            } else {
                List(viewModel.events) { event in
                    EventRowView(event: event)
                        .listRowSeparator(.visible)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                }
                .listStyle(.plain)
            }
        }
    }

    private var rawList: some View {
        Group {
            if viewModel.bleFrames.isEmpty {
                ContentUnavailableView(
                    String(localized: "doors.events.raw_empty", bundle: .module),
                    systemImage: Icons.emptyRaw
                )
            } else {
                List(viewModel.bleFrames) { frame in
                    BLEEventRowView(frame: frame)
                        .listRowSeparator(.visible)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Constants

extension DoorDetailView {
    enum Layout {
        static let toggleAnimationDuration: Double = 0.2
    }

    enum Icons {
        static let emptyEvents = "clock.badge.xmark"
        static let emptyRaw = "waveform.path.ecg"
    }
}

// MARK: - Preview

#Preview("Door Detail") {
    NavigationStack {
        DoorDetailView(door: Door(
            id: 1,
            name: "Main Entrance",
            serial: "SN-001",
            lockMac: "AA:BB:CC:DD:EE:FF",
            address: "123 Main St",
            latitude: nil,
            longitude: nil,
            battery: 82
        ))
    }
}
