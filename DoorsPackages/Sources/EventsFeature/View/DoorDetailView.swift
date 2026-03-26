//
//  DoorDetailView.swift
//

import DesignSystemKit
import DomainKit
import SwiftUI

public struct DoorDetailView: View {
    let door: Door
    @State private var viewModel: EventsViewModel
    @State private var useNewUI = false
    @State private var bleSimulationEnabled = false
    private let featureFlags: any FeatureFlagServiceProtocol

    public init(door: Door, featureFlags: any FeatureFlagServiceProtocol) {
        self.door = door
        self.featureFlags = featureFlags
        _viewModel = State(initialValue: EventsViewModel(doorId: String(door.id), featureFlags: featureFlags))
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView(String(localized: "doors.events.loading", bundle: .module))
            } else if useNewUI {
                newDetailContent
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
        .safeAreaInset(edge: .bottom) {
            if bleSimulationEnabled {
                PrimaryActionButton(
                    String(localized: "doors.events.simulate", bundle: .module),
                    isLoading: viewModel.isSimulating,
                    action: viewModel.onSimulateEvent
                )
                .padding(.horizontal)
                .padding(.bottom, Layout.simulateButtonBottomPadding)
            }
        }
        .toolbar {
            if !useNewUI && bleSimulationEnabled {
                ToolbarItem(placement: .navigationBarLeading) {
                    let label = viewModel.showRaw
                        ? String(localized: "doors.events.tab_parsed", bundle: .module)
                        : String(localized: "doors.events.tab_raw", bundle: .module)
                    Button(label) {
                        viewModel.onToggleRaw()
                    }
                }
            }
            if hasFilterOptions {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterMenu
                }
            }
        }
        .errorAlert(message: $viewModel.errorMessage)
        .onAppear { viewModel.onAppear() }
        .task {
            async let newUI = featureFlags.isEnabled(.newDoorDetailUI)
            async let bleMode = featureFlags.isEnabled(.bleSimulationMode)
            useNewUI = await newUI
            bleSimulationEnabled = await bleMode
            if !bleSimulationEnabled && viewModel.showRaw {
                viewModel.showRaw = false
            }
        }
    }

    private var newDetailContent: some View {
        VStack(spacing: 0) {
            doorInfoBanner

            if bleSimulationEnabled {
                Picker("", selection: Binding(
                    get: { viewModel.showRaw },
                    set: { newVal in if newVal != viewModel.showRaw { viewModel.onToggleRaw() } }
                )) {
                    Text(String(localized: "doors.events.tab_parsed", bundle: .module)).tag(false)
                    Text(String(localized: "doors.events.tab_raw", bundle: .module)).tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
            }

            if viewModel.showRaw, bleSimulationEnabled {
                rawList
            } else {
                eventsList
            }
        }
    }

    private var doorInfoBanner: some View {
        VStack(alignment: .leading, spacing: Layout.infoSpacing) {
            if let address = door.address {
                Label(address, systemImage: "mappin.and.ellipse")
            }
            HStack(spacing: Layout.infoChipSpacing) {
                if let serial = door.serial {
                    doorChip(icon: "barcode", text: serial)
                }
                if let mac = door.lockMac {
                    doorChip(icon: "lock.fill", text: mac)
                }
                if let battery = door.battery {
                    doorChip(icon: batteryIcon(battery), text: "\(battery)%")
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, Layout.infoPaddingTop)
    }

    private func doorChip(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .padding(.horizontal, Layout.chipPaddingH)
            .padding(.vertical, Layout.chipPaddingV)
            .background(.quaternary, in: Capsule())
    }

    private func batteryIcon(_ level: Int) -> String {
        switch level {
        case 76...: "battery.100"
        case 51...: "battery.75"
        case 26...: "battery.50"
        default: "battery.25"
        }
    }

    private var hasFilterOptions: Bool {
        viewModel.showRaw
            ? viewModel.availableBLEFilters.count > 1
            : viewModel.availableFilters.count > 1
    }

    private var filterMenu: some View {
        let isActive = viewModel.showRaw
            ? viewModel.selectedBLEFilter != .all
            : viewModel.selectedFilter != .all
        return Menu {
            if viewModel.showRaw {
                ForEach(viewModel.availableBLEFilters, id: \.self) { filter in
                    Button {
                        viewModel.selectedBLEFilter = filter
                    } label: {
                        if viewModel.selectedBLEFilter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            } else {
                ForEach(viewModel.availableFilters, id: \.self) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        if viewModel.selectedFilter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: isActive
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
        }
    }

    private var eventsList: some View {
        Group {
            if viewModel.events.isEmpty {
                ContentUnavailableView(
                    String(localized: "doors.events.empty", bundle: .module),
                    systemImage: Icons.emptyEvents
                )
            } else if viewModel.filteredEvents.isEmpty {
                ContentUnavailableView(
                    "No \(viewModel.selectedFilter.rawValue) events",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            } else {
                List(viewModel.filteredEvents) { event in
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
            } else if viewModel.filteredBLEFrames.isEmpty {
                ContentUnavailableView(
                    "No \(viewModel.selectedBLEFilter.rawValue) frames",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            } else {
                List(viewModel.filteredBLEFrames) { frame in
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
        static let infoSpacing: CGFloat = 4
        static let infoChipSpacing: CGFloat = 6
        static let infoPaddingTop: CGFloat = 8
        static let chipPaddingH: CGFloat = 8
        static let chipPaddingV: CGFloat = 4
        static let simulateButtonBottomPadding: CGFloat = 8
    }

    enum Icons {
        static let emptyEvents = "clock.badge.xmark"
        static let emptyRaw = "waveform.path.ecg"
    }
}

// MARK: - Preview

private struct PreviewFeatureFlags: FeatureFlagServiceProtocol {
    func isEnabled(_: FeatureFlag) async -> Bool {
        false
    }

    func stringValue(for _: FeatureFlag) async -> String {
        ""
    }
}

#Preview("Door Detail") {
    NavigationStack {
        DoorDetailView(
            door: Door(
                id: 1,
                name: "Main Entrance",
                serial: "SN-001",
                lockMac: "AA:BB:CC:DD:EE:FF",
                address: "123 Main St",
                latitude: nil,
                longitude: nil,
                battery: 82
            ),
            featureFlags: PreviewFeatureFlags()
        )
    }
}
