import DomainKit
import SwiftUI

public struct DoorsListView: View {
    @State private var viewModel = DoorsListViewModel()
    private let onSignOut: () -> Void

    public init(onSignOut: @escaping () -> Void) {
        self.onSignOut = onSignOut
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.doors.isEmpty {
                    ProgressView("Loading doors…")
                } else if viewModel.doors.isEmpty {
                    ContentUnavailableView("No Doors Found", systemImage: "door.left.hand.closed")
                } else {
                    list
                }
            }
            .navigationTitle("Doors")
            .searchable(text: $viewModel.searchQuery, prompt: "Search by name")
            .onChange(of: viewModel.searchQuery) { viewModel.onSearchQueryChanged() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out", action: onSignOut)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear { viewModel.onAppear() }
    }

    private var list: some View {
        List {
            ForEach(viewModel.doors) { door in
                NavigationLink(destination: DoorDetailView(door: door)) {
                    DoorRowView(door: door)
                }
                .onAppear { viewModel.onItemAppear(door) }
            }
            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
    }
}
