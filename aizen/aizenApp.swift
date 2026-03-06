//
//  aizenApp.swift
//  aizen
//
//  Created by Hemanth Krishna on 01/03/26.
//

import Sparkle
import SwiftUI

@main
struct aizenApp: App {
    private let updaterController: SPUStandardUpdaterController
    @State private var usageManager = UsageManager()

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(usageManager: usageManager, updater: updaterController.updater)
        } label: {
            if usageManager.isCompactMode {
                Text(usageManager.menuBarSummaryText)
            } else {
                Label {
                    Text(usageManager.menuBarSummaryText)
                } icon: {
                    Image("MenuBarIcon")
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
