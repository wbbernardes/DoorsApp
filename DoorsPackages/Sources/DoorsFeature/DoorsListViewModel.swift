import DomainKit
import SwiftUI

@MainActor
@Observable
public final class DoorsListViewModel {
    public var doors: [Door] = []
    public var isLoading = false
    public var isLoadingNextPage = false
    public var errorMessage: String?
    public var searchQuery = ""

    private var currentPage = 1
    private var hasMore = true
    private let pageSize = 20
    private var searchTask: Task<Void, Never>?

    private let fetchDoorsUseCase: FetchDoorsUseCase
    private let searchDoorsUseCase: SearchDoorsUseCase

    public init(
        fetchDoorsUseCase: FetchDoorsUseCase = .init(repository: DoorsRepositoryImpl()),
        searchDoorsUseCase: SearchDoorsUseCase = .init(repository: DoorsRepositoryImpl())
    ) {
        self.fetchDoorsUseCase = fetchDoorsUseCase
        self.searchDoorsUseCase = searchDoorsUseCase
    }

    public func onAppear() {
        Task { await loadFirstPage() }
    }

    public func onSearchQueryChanged() {
        searchTask?.cancel()
        if searchQuery.isEmpty {
            Task { await loadFirstPage() }
        } else {
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                await searchFirstPage()
            }
        }
    }

    public func onItemAppear(_ door: Door) {
        guard !isLoadingNextPage, hasMore else { return }
        guard door.id == doors.last?.id else { return }
        Task { await loadNextPage() }
    }

    private func loadFirstPage() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMore = true
        do {
            let result = try await fetchDoorsUseCase.execute(page: 1, limit: pageSize)
            doors = result.data
            hasMore = result.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func searchFirstPage() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMore = true
        do {
            let result = try await searchDoorsUseCase.execute(query: searchQuery, page: 1, limit: pageSize)
            doors = result.data
            hasMore = result.hasMore
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
                ? try await fetchDoorsUseCase.execute(page: nextPage, limit: pageSize)
                : try await searchDoorsUseCase.execute(query: searchQuery, page: nextPage, limit: pageSize)
            doors.append(contentsOf: result.data)
            currentPage = nextPage
            hasMore = result.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingNextPage = false
    }
}
