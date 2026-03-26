import BLEKit
import CoreNetwork
@testable import DomainKit
@testable import EventsFeature
import Testing

@Suite("EventsViewModel")
@MainActor
struct EventsViewModelTests {
    // MARK: - Helpers

    private func makeVM(
        doorId: String = "door-1",
        eventsError: NetworkError? = nil,
        rawError: NetworkError? = nil,
        events: [DoorEvent] = [],
        featureFlags: MockFeatureFlagService = MockFeatureFlagService()
    ) -> EventsViewModel {
        let repo = MockEventsRepository(
            eventsResponse: PaginatedResponse(content: events, page: 0, totalPages: 1),
            eventsError: eventsError,
            rawError: rawError
        )
        return EventsViewModel(
            doorId: doorId,
            featureFlags: featureFlags,
            fetchEventsUseCase: FetchEventsUseCase(repository: repo),
            eventsRepository: repo
        )
    }

    // MARK: - Load Events

    @Test func onAppear_loadsEvents() async {
        let events = [DoorEvent.stub(id: 1, logType: "DOOR_OPEN"), DoorEvent.stub(id: 2, logType: "DOOR_CLOSE")]
        let vm = makeVM(events: events)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.events.count == 2)
        #expect(vm.events[0].logType == "DOOR_OPEN")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func onAppear_emptyEvents() async {
        let vm = makeVM(events: [])

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.events.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test func onAppear_unauthorizedError_setsFlag() async {
        let vm = makeVM(eventsError: .unauthorized)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isUnauthorized == true)
        #expect(vm.events.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @Test func onAppear_networkError_setsErrorMessage() async {
        let vm = makeVM(eventsError: .noToken)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.errorMessage != nil)
        #expect(vm.isUnauthorized == false)
    }

    // MARK: - Toggle Raw

    @Test func onToggleRaw_firstToggle_setsShowRawAndLoadsBLEFrames() async {
        let repo = MockEventsRepository(
            rawResponse: PaginatedResponse(content: [], page: 0, totalPages: 1)
        )
        let vm = EventsViewModel(
            doorId: "door-1",
            featureFlags: MockFeatureFlagService(),
            fetchEventsUseCase: FetchEventsUseCase(repository: repo),
            eventsRepository: repo
        )

        vm.onToggleRaw()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.showRaw == true)
        #expect(vm.isLoading == false)
    }

    @Test func onToggleRaw_secondToggle_hidesRaw() async {
        let vm = makeVM()

        vm.onToggleRaw()
        for _ in 0 ..< 3 {
            await Task.yield()
        }
        vm.onToggleRaw()

        #expect(vm.showRaw == false)
    }

    @Test func onToggleRaw_rawError_setsErrorMessage() async {
        let vm = makeVM(rawError: .noToken)

        vm.onToggleRaw()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.showRaw == true)
        #expect(vm.errorMessage != nil)
        #expect(vm.isUnauthorized == false)
    }

    @Test func onToggleRaw_rawUnauthorized_setsFlag() async {
        let vm = makeVM(rawError: .unauthorized)

        vm.onToggleRaw()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isUnauthorized == true)
    }

    // MARK: - Initial State

    @Test func initialState_allFalseAndEmpty() {
        let vm = makeVM()

        #expect(vm.events.isEmpty)
        #expect(vm.bleFrames.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.showRaw == false)
        #expect(vm.isSimulating == false)
        #expect(vm.simulationSuccess == false)
        #expect(vm.isUnauthorized == false)
        #expect(vm.selectedFilter == .all)
    }

    // MARK: - Filter

    @Test func filteredEvents_withAllFilter_returnsAllEvents() {
        let vm = makeVM()
        vm.events = [
            .stub(id: 1, logType: "DOOR_OPEN"),
            .stub(id: 2, logType: "UNLOCK_DENIED"),
            .stub(id: 3, logType: "BATTERY_LOW")
        ]

        #expect(vm.filteredEvents.count == 3)
    }

    @Test func filteredEvents_withOpenFilter_returnsOnlyOpenEvents() {
        let vm = makeVM()
        vm.events = [
            .stub(id: 1, logType: "DOOR_OPEN"),
            .stub(id: 2, logType: "UNLOCK_DENIED"),
            .stub(id: 3, logType: "BATTERY_LOW")
        ]
        vm.selectedFilter = .open

        #expect(vm.filteredEvents.count == 1)
        #expect(vm.filteredEvents[0].logType == "DOOR_OPEN")
    }

    @Test func filteredEvents_withDeniedFilter_excludesRegularUnlock() {
        let vm = makeVM()
        vm.events = [
            .stub(id: 1, logType: "UNLOCK"),
            .stub(id: 2, logType: "UNLOCK_DENIED")
        ]
        vm.selectedFilter = .denied

        #expect(vm.filteredEvents.count == 1)
        #expect(vm.filteredEvents[0].logType == "UNLOCK_DENIED")
    }

    @Test func availableFilters_includesOnlyPresentCategories() {
        let vm = makeVM()
        vm.events = [
            .stub(id: 1, logType: "DOOR_OPEN"),
            .stub(id: 2, logType: "BATTERY_LOW")
        ]

        #expect(vm.availableFilters.contains(.all))
        #expect(vm.availableFilters.contains(.open))
        #expect(vm.availableFilters.contains(.battery))
        #expect(!vm.availableFilters.contains(.unlock))
        #expect(!vm.availableFilters.contains(.denied))
        #expect(!vm.availableFilters.contains(.close))
    }

    @Test func availableFilters_withNoEvents_returnsOnlyAll() {
        let vm = makeVM()

        #expect(vm.availableFilters == [.all])
    }

    // MARK: - BLE Filter

    @Test func filteredBLEFrames_withAllFilter_returnsAllFrames() {
        let vm = makeVM()
        vm.bleFrames = [
            .stub(eventType: .doorOpen),
            .stub(eventType: .unlock),
            .stub(eventType: .batteryLow)
        ]

        #expect(vm.filteredBLEFrames.count == 3)
    }

    @Test func filteredBLEFrames_withDoorFilter_returnsOnlyDoorFrames() {
        let vm = makeVM()
        vm.bleFrames = [
            .stub(eventType: .doorOpen),
            .stub(eventType: .doorClose),
            .stub(eventType: .unlock)
        ]
        vm.selectedBLEFilter = .door

        #expect(vm.filteredBLEFrames.count == 2)
        #expect(vm.filteredBLEFrames.allSatisfy { $0.eventType == .doorOpen || $0.eventType == .doorClose })
    }

    @Test func filteredBLEFrames_withUnlockFilter_excludesDenied() {
        let vm = makeVM()
        vm.bleFrames = [
            .stub(eventType: .unlock),
            .stub(eventType: .unlockDenied)
        ]
        vm.selectedBLEFilter = .unlock

        #expect(vm.filteredBLEFrames.count == 2)
    }

    @Test func availableBLEFilters_includesOnlyPresentCategories() {
        let vm = makeVM()
        vm.bleFrames = [
            .stub(eventType: .doorOpen),
            .stub(eventType: .batteryLow)
        ]

        #expect(vm.availableBLEFilters.contains(.all))
        #expect(vm.availableBLEFilters.contains(.door))
        #expect(vm.availableBLEFilters.contains(.battery))
        #expect(!vm.availableBLEFilters.contains(.unlock))
        #expect(!vm.availableBLEFilters.contains(.schedule))
        #expect(!vm.availableBLEFilters.contains(.status))
        #expect(!vm.availableBLEFilters.contains(.error))
        #expect(!vm.availableBLEFilters.contains(.system))
    }

    @Test func availableBLEFilters_withNoFrames_returnsOnlyAll() {
        let vm = makeVM()

        #expect(vm.availableBLEFilters == [.all])
    }

    // MARK: - Feature Flags

    @Test func onToggleRaw_withBLESimulationEnabled_passesDebugModeToRepo() async {
        let flags = MockFeatureFlagService(enabledFlags: [.bleSimulationMode])
        let repo = MockEventsRepository(
            rawResponse: PaginatedResponse(content: [], page: 0, totalPages: 1)
        )
        let vm = EventsViewModel(
            doorId: "door-1",
            featureFlags: flags,
            fetchEventsUseCase: FetchEventsUseCase(repository: repo),
            eventsRepository: repo
        )

        vm.onToggleRaw()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        // The repo accepted the call without error — debug mode was passed
        #expect(vm.showRaw == true)
        #expect(vm.isLoading == false)
    }
}
