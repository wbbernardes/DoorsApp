import BLEKit
import CoreNetwork
import DomainKit
import Observation

// MARK: - EventFilter

enum EventFilter: String, CaseIterable, Equatable {
    case all = "All"
    case open = "Open"
    case close = "Close"
    case unlock = "Unlock"
    case denied = "Denied"
    case battery = "Battery"
    case error = "Error"

    func matches(_ logType: String) -> Bool {
        switch self {
        case .all: return true
        case .open: return logType.contains("OPEN")
        case .close: return logType.contains("CLOSE")
        case .unlock: return logType.contains("UNLOCK") && !logType.contains("DENIED")
        case .denied: return logType.contains("DENIED")
        case .battery: return logType.contains("BATTERY")
        case .error: return logType.contains("ERROR")
        }
    }
}

// MARK: - BLEFilter

enum BLEFilter: String, CaseIterable, Equatable {
    case all = "All"
    case door = "Door"
    case unlock = "Unlock"
    case battery = "Battery"
    case schedule = "Schedule"
    case status = "Status"
    case error = "Error"
    case system = "System"

    func matches(_ eventType: BLEEventType) -> Bool {
        switch self {
        case .all: return true
        case .door: return [.doorOpen, .doorClose].contains(eventType)
        case .unlock: return [.unlock, .unlockDenied, .touchUnlock].contains(eventType)
        case .battery: return eventType == .batteryLow
        case .schedule: return [.scheduleStart, .scheduleFinish, .scheduleTouchCancel, .scheduleCancel, .scheduleInit].contains(eventType)
        case .status: return [.statusPrivate, .statusKey, .statusHalfOpen, .statusDfu].contains(eventType)
        case .error: return [.error, .systemError, .eepromWriteError, .eepromCrcError].contains(eventType)
        case .system: return [.setup, .manufacture, .configuration, .reset, .logFull, .unknown].contains(eventType)
        }
    }
}

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
    var selectedFilter: EventFilter = .all
    var selectedBLEFilter: BLEFilter = .all

    var filteredEvents: [DoorEvent] {
        guard selectedFilter != .all else { return events }
        return events.filter { selectedFilter.matches($0.logType) }
    }

    var filteredBLEFrames: [BLEFrame] {
        guard selectedBLEFilter != .all else { return bleFrames }
        return bleFrames.filter { selectedBLEFilter.matches($0.eventType) }
    }

    var availableFilters: [EventFilter] {
        var result: [EventFilter] = [.all]
        for filter in EventFilter.allCases where filter != .all {
            if events.contains(where: { filter.matches($0.logType) }) {
                result.append(filter)
            }
        }
        return result
    }

    var availableBLEFilters: [BLEFilter] {
        var result: [BLEFilter] = [.all]
        for filter in BLEFilter.allCases where filter != .all {
            if bleFrames.contains(where: { filter.matches($0.eventType) }) {
                result.append(filter)
            }
        }
        return result
    }

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
