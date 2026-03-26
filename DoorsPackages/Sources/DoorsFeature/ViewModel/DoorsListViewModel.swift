import CoreNetwork
import DomainKit
import Foundation
import Observation

@MainActor
@Observable
final class DoorsListViewModel {
    // MARK: - Local UI State

    var doors: [Door] = []
    var isLoading = false
    var isLoadingNextPage = false
    var errorMessage: String?
    var searchQuery = ""
    var isUnauthorized = false

    // MARK: - Dependencies

    private let fetchDoorsUseCase: FetchDoorsUseCase
    private let searchDoorsUseCase: SearchDoorsUseCase

    // MARK: - Private State

    private var currentPage = 0
    private var hasMore = true
    private let pageSize = 20
    private var queryTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        fetchDoorsUseCase: FetchDoorsUseCase = .init(repository: DoorsRepositoryImpl()),
        searchDoorsUseCase: SearchDoorsUseCase = .init(repository: DoorsRepositoryImpl())
    ) {
        self.fetchDoorsUseCase = fetchDoorsUseCase
        self.searchDoorsUseCase = searchDoorsUseCase
    }

    // MARK: - Actions

    func onAppear() {
        Task { await loadFirstPage() }
    }

    func onRefresh() async {
        await loadFirstPage()
    }

    func onSearchQueryChanged() {
        queryTask?.cancel()
        queryTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            if searchQuery.isEmpty {
                await loadFirstPage()
            } else {
                await searchFirstPage()
            }
        }
    }

    func onItemAppear(_ door: Door) {
        guard !isLoadingNextPage, hasMore else { return }
        guard door.id == doors.last?.id else { return }
        Task { await loadNextPage() }
    }

    // MARK: - Private

    private func loadFirstPage() async {
        isLoading = true
        errorMessage = nil
        currentPage = 0
        hasMore = true
        do {
            let result = try await fetchDoorsUseCase.execute(page: 0, size: pageSize)
            doors = result.content
            hasMore = result.hasMore
        } catch NetworkError.unauthorized {
            isUnauthorized = true
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func searchFirstPage() async {
        isLoading = true
        errorMessage = nil
        currentPage = 0
        hasMore = true
        do {
            let result = try await searchDoorsUseCase.execute(name: searchQuery, page: 0, size: pageSize)
            doors = result.content
            hasMore = result.hasMore
        } catch NetworkError.unauthorized {
            isUnauthorized = true
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadNextPage() async {
        isLoadingNextPage = true
        let nextPage = currentPage + 1
        do {
            let result = searchQuery.isEmpty
                ? try await fetchDoorsUseCase.execute(page: nextPage, size: pageSize)
                : try await searchDoorsUseCase.execute(name: searchQuery, page: nextPage, size: pageSize)
            doors.append(contentsOf: result.content)
            currentPage = nextPage
            hasMore = result.hasMore
        } catch NetworkError.unauthorized {
            isUnauthorized = true
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingNextPage = false
    }
}
