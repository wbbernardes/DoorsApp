import DomainKit
import SwiftUI

@MainActor
@Observable
public final class EventsViewModel {
    public var events: [DoorEvent] = []
    public var bleFrames: [BLEFrame] = []
    public var isLoading = false
    public var errorMessage: String?
    public var showRaw = false

    private let doorId: String
    private let fetchEventsUseCase: FetchEventsUseCase
    private let parseFrameUseCase = ParseBLEFrameUseCase()
    private let eventsRepository: any EventsRepository

    public init(
        doorId: String,
        fetchEventsUseCase: FetchEventsUseCase = .init(repository: EventsRepositoryImpl()),
        eventsRepository: any EventsRepository = EventsRepositoryImpl()
    ) {
        self.doorId = doorId
        self.fetchEventsUseCase = fetchEventsUseCase
        self.eventsRepository = eventsRepository
    }

    public func onAppear() {
        Task { await load() }
    }

    public func onToggleRaw() {
        showRaw.toggle()
        if showRaw && bleFrames.isEmpty {
            Task { await loadRaw() }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            events = try await fetchEventsUseCase.execute(doorId: doorId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadRaw() async {
        isLoading = true
        do {
            let rawList = try await eventsRepository.fetchRawEvents(doorId: doorId)
            bleFrames = rawList.compactMap { try? parseFrameUseCase.execute(base64: $0) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
