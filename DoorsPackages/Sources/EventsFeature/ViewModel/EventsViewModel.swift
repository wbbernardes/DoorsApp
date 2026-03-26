import BLEKit
import CoreNetwork
import DomainKit
import Observation

@MainActor
@Observable
final class EventsViewModel {
    // MARK: - Local UI State

    var events: [DoorEvent] = []
    var bleFrames: [BLEFrame] = []
    var isLoading = false
    var errorMessage: String?
    var showRaw = false
    var isUnauthorized = false
    var isSimulating = false
    var simulationSuccess = false

    // MARK: - Dependencies

    private let doorId: String
    private let featureFlags: any FeatureFlagServiceProtocol
    private let fetchEventsUseCase: FetchEventsUseCase
    private let parseFrameUseCase = ParseBLEFrameUseCase()
    private let eventsRepository: any EventsRepository

    // MARK: - Initialization

    init(
        doorId: String,
        featureFlags: any FeatureFlagServiceProtocol,
        fetchEventsUseCase: FetchEventsUseCase = .init(repository: EventsRepositoryImpl()),
        eventsRepository: any EventsRepository = EventsRepositoryImpl()
    ) {
        self.doorId = doorId
        self.featureFlags = featureFlags
        self.fetchEventsUseCase = fetchEventsUseCase
        self.eventsRepository = eventsRepository
    }

    // MARK: - Actions

    func onAppear() {
        Task { await load() }
    }

    func onSimulateEvent() {
        Task { await simulateEvent() }
    }

    func onToggleRaw() {
        showRaw.toggle()
        if showRaw, bleFrames.isEmpty {
            Task { await loadRaw() }
        }
    }

    // MARK: - Private

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await fetchEventsUseCase.execute(doorId: doorId)
            events = response.content
        } catch NetworkError.unauthorized {
            isUnauthorized = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func simulateEvent() async {
        isSimulating = true
        do {
            let debugMode = await featureFlags.isEnabled(.bleSimulationMode)
            try await APIClient.shared.requestVoid(.simulateEvent(count: 1, logType: "DOOR_OPEN", debug: debugMode))
            simulationSuccess = true
            if showRaw {
                bleFrames = []
                await loadRaw()
            } else {
                await load()
            }
        } catch NetworkError.unauthorized {
            isUnauthorized = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSimulating = false
    }

    private func loadRaw() async {
        isLoading = true
        do {
            let debugMode = await featureFlags.isEnabled(.bleSimulationMode)
            let response = try await eventsRepository
                .fetchRawEvents(doorId: doorId, page: 0, size: 50, debug: debugMode)
            bleFrames = response.content.compactMap { try? parseFrameUseCase.execute(base64: $0.logEvent) }
        } catch NetworkError.unauthorized {
            isUnauthorized = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
