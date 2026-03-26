//
//  DoorsListView.swift
//

import DesignSystemKit
import DomainKit
import SwiftUI

public struct DoorsListView: View {
    @State private var viewModel = DoorsListViewModel()
    private let onSignOut: () -> Void

    public init(onSignOut: @escaping () -> Void) {
        self.onSignOut = onSignOut
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.doors.isEmpty {
                ProgressView(String(localized: "doors.loading", bundle: .module))
            } else if viewModel.doors.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    String(localized: "doors.empty", bundle: .module),
                    systemImage: Icons.emptyDoors
                )
            } else {
                list
            }
        }
        .navigationTitle(Text("doors.title", bundle: .module))
        .searchable(
            text: $viewModel.searchQuery,
            prompt: String(localized: "doors.search_prompt", bundle: .module)
        )
        .onChange(of: viewModel.searchQuery) { viewModel.onSearchQueryChanged() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "doors.sign_out", bundle: .module), action: onSignOut)
            }
        }
        .errorAlert(message: $viewModel.errorMessage)
        .onChange(of: viewModel.isUnauthorized) {
            if viewModel.isUnauthorized { onSignOut() }
        }
        .onAppear { viewModel.onAppear() }
    }

    private var list: some View {
        List {
            ForEach(viewModel.doors) { door in
                NavigationLink(value: door) {
                    DoorRowView(door: door)
                }
                .onAppear { viewModel.onItemAppear(door) }
            }
            if viewModel.isLoadingNextPage {
                PaginationLoadingFooter()
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Constants

extension DoorsListView {
    enum Icons {
        static let emptyDoors = "door.left.hand.closed"
    }
}

// MARK: - Preview

#Preview("Doors List") {
    NavigationStack {
        DoorsListView(onSignOut: {})
    }
}
