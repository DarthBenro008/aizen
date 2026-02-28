//
//  aizenApp.swift
//  aizen
//
//  Created by Hemanth Krishna on 01/03/26.
//

import SwiftUI

@main
struct aizenApp: App {
    @State private var usageManager = UsageManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(usageManager: usageManager)
        } label: {
            Label {
                Text(usageManager.menuBarSummaryText)
            } icon: {
                Image("MenuBarIcon")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
