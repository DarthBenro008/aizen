//
//  UpdaterService.swift
//  aizen
//

import Combine
import Sparkle

/// View model that bridges Sparkle's KVO-based `canCheckForUpdates` property
/// into a SwiftUI-compatible `@Published` property via Combine.
///
/// This is the ONLY file in the project that imports Combine.
/// Sparkle uses KVO (not @Observable), so ObservableObject + Combine is required here.
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
