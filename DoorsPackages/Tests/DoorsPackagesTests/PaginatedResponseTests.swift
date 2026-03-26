@testable import DomainKit
import Testing

@Suite("PaginatedResponse")
struct PaginatedResponseTests {
    @Test func hasMore_whenMorePagesExist() {
        let response = PaginatedResponse<Door>(content: [], page: 0, totalPages: 3)
        #expect(response.hasMore == true)
    }

    @Test func hasMore_onLastPage() {
        let response = PaginatedResponse<Door>(content: [], page: 2, totalPages: 3)
        #expect(response.hasMore == false)
    }

    @Test func hasMore_onSinglePage() {
        let response = PaginatedResponse<Door>(content: [], page: 0, totalPages: 1)
        #expect(response.hasMore == false)
    }

    @Test func hasMore_whenTotalPagesIsZero() {
        let response = PaginatedResponse<Door>(content: [], page: 0, totalPages: 0)
        #expect(response.hasMore == false)
    }

    @Test func hasMore_middlePageOfMany() {
        let response = PaginatedResponse<Door>(content: [], page: 3, totalPages: 10)
        #expect(response.hasMore == true)
    }

    @Test func content_isPreserved() {
        let doors = [Door.stub(id: 1), Door.stub(id: 2)]
        let response = PaginatedResponse<Door>(content: doors, page: 0, totalPages: 2)
        #expect(response.content.count == 2)
        #expect(response.content[0].id == 1)
        #expect(response.content[1].id == 2)
    }
}
