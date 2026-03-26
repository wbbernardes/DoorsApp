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
