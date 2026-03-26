import Observation
import SwiftUI

/// Owns the navigation state for the authenticated app flow.
/// Acts as the composition root for routing between Doors and Events.
@Observable
final class AppCoordinator {
    var navigationPath = NavigationPath()
    let container = DependencyContainer()
}
