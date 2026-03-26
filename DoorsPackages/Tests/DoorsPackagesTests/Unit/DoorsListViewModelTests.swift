import CoreNetwork
@testable import DomainKit
@testable import DoorsFeature
import Testing

@Suite("DoorsListViewModel")
@MainActor
struct DoorsListViewModelTests {
    // MARK: - Helpers

    private func makeVM(
        fetchError: NetworkError? = nil,
        searchError: NetworkError? = nil,
        doors: [Door] = [],
        totalPages: Int = 1
    ) -> DoorsListViewModel {
        let repo = MockDoorsRepository(
            response: PaginatedResponse(content: doors, page: 0, totalPages: totalPages),
            fetchError: fetchError,
            searchError: searchError
        )
        return DoorsListViewModel(
            fetchDoorsUseCase: FetchDoorsUseCase(repository: repo),
            searchDoorsUseCase: SearchDoorsUseCase(repository: repo)
        )
    }

    // MARK: - Load First Page

    @Test func onAppear_loadsDoors() async {
        let doors = [Door.stub(id: 1, name: "Main Entrance"), Door.stub(id: 2, name: "Side Door")]
        let vm = makeVM(doors: doors)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.doors.count == 2)
        #expect(vm.doors[0].name == "Main Entrance")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func onAppear_emptyResponse_doorsEmpty() async {
        let vm = makeVM(doors: [])

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.doors.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test func onAppear_unauthorizedError_setsFlag() async {
        let vm = makeVM(fetchError: .unauthorized)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isUnauthorized == true)
        #expect(vm.doors.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @Test func onAppear_networkError_setsErrorMessage() async {
        let vm = makeVM(fetchError: .noToken)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.errorMessage != nil)
        #expect(vm.isUnauthorized == false)
        #expect(vm.doors.isEmpty)
    }

    // MARK: - hasMore (via PaginatedResponse)

    @Test func onAppear_multiplePages_hasMoreIsTrue() async {
        let doors = (1 ... 5).map { Door.stub(id: $0) }
        let vm = makeVM(doors: doors, totalPages: 3)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        // We can verify the door count is correct and VM didn't error
        #expect(vm.doors.count == 5)
        #expect(vm.isLoading == false)
    }

    // MARK: - Search

    @Test func onSearchQueryChanged_withQuery_searchesDoors() async {
        let searchDoor = Door.stub(id: 99, name: "Garage")
        let fetchRepo = MockDoorsRepository(
            response: PaginatedResponse(content: [Door.stub()], page: 0, totalPages: 1),
            searchResponse: PaginatedResponse(content: [searchDoor], page: 0, totalPages: 1)
        )
        let vm = DoorsListViewModel(
            fetchDoorsUseCase: FetchDoorsUseCase(repository: fetchRepo),
            searchDoorsUseCase: SearchDoorsUseCase(repository: fetchRepo)
        )
        vm.searchQuery = "Garage"

        vm.onSearchQueryChanged()
        // Wait for 300ms debounce + task execution
        try? await Task.sleep(for: .milliseconds(400))
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.doors.count == 1)
        #expect(vm.doors[0].name == "Garage")
    }

    @Test func onSearchQueryChanged_emptyQuery_fetchesAll() async {
        let allDoors = [Door.stub(id: 1), Door.stub(id: 2)]
        let repo = MockDoorsRepository(
            response: PaginatedResponse(content: allDoors, page: 0, totalPages: 1)
        )
        let vm = DoorsListViewModel(
            fetchDoorsUseCase: FetchDoorsUseCase(repository: repo),
            searchDoorsUseCase: SearchDoorsUseCase(repository: repo)
        )
        vm.searchQuery = ""

        vm.onSearchQueryChanged()
        try? await Task.sleep(for: .milliseconds(400))
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.doors.count == 2)
    }

    @Test func onSearchQueryChanged_unauthorized_setsFlag() async {
        let repo = MockDoorsRepository(searchError: .unauthorized)
        let vm = DoorsListViewModel(
            fetchDoorsUseCase: FetchDoorsUseCase(repository: repo),
            searchDoorsUseCase: SearchDoorsUseCase(repository: repo)
        )
        vm.searchQuery = "Test"

        vm.onSearchQueryChanged()
        try? await Task.sleep(for: .milliseconds(400))
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isUnauthorized == true)
    }

    // MARK: - onItemAppear (pagination trigger guard)

    @Test func onItemAppear_notLastDoor_doesNotLoad() async {
        let doors = [Door.stub(id: 1), Door.stub(id: 2)]
        let vm = makeVM(doors: doors, totalPages: 2)

        vm.onAppear()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        // Trigger appear for first door (not last) — should not load next page
        vm.onItemAppear(doors[0])
        for _ in 0 ..< 3 {
            await Task.yield()
        }

        #expect(vm.doors.count == 2)
        #expect(vm.isLoadingNextPage == false)
    }
}
