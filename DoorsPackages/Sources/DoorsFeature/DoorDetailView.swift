import DomainKit
import SwiftUI

public struct DoorDetailView: View {
    let door: Door
    @State private var viewModel: EventsViewModel

    public init(door: Door) {
        self.door = door
        self._viewModel = State(initialValue: EventsViewModel(doorId: door.id))
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading events…")
            } else if viewModel.showRaw {
                rawList
            } else {
                eventsList
            }
        }
        .navigationTitle(door.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.showRaw ? "Parsed" : "Raw BLE") {
                    viewModel.onToggleRaw()
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.onAppear() }
    }

    private var eventsList: some View {
        Group {
            if viewModel.events.isEmpty {
                ContentUnavailableView("No Events", systemImage: "clock.badge.xmark")
            } else {
                List(viewModel.events) { event in
                    EventRowView(event: event)
                }
                .listStyle(.plain)
            }
        }
    }

    private var rawList: some View {
        Group {
            if viewModel.bleFrames.isEmpty {
                ContentUnavailableView("No Raw Events", systemImage: "waveform.path.ecg")
            } else {
                List(viewModel.bleFrames, id: \.logCode) { frame in
                    BLEEventRowView(frame: frame)
                }
                .listStyle(.plain)
            }
        }
    }
}
