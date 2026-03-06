import AppKit
import Sparkle
import SwiftUI

struct MenuBarView: View {
    @Bindable var usageManager: UsageManager
    @ObservedObject private var checkForUpdatesVM: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(usageManager: UsageManager, updater: SPUUpdater) {
        self.usageManager = usageManager
        self.updater = updater
        self.checkForUpdatesVM = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(usageManager.providerStates) { state in
                ProviderCardView(state: state)
            }

            Divider()

            HStack {
                Text(usageManager.lastUpdatedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                if usageManager.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack(spacing: 10) {
                Button("Refresh") {
                    Task {
                        await usageManager.refresh()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Spacer(minLength: 8)

                Toggle("Compact", isOn: $usageManager.isCompactMode)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Spacer(minLength: 8)

                Button("Check for Updates") {
                    updater.checkForUpdates()
                }
                .disabled(!checkForUpdatesVM.canCheckForUpdates)

                Spacer(minLength: 8)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
        .frame(width: 380)
        .padding(12)
        .onAppear {
            Task {
                await usageManager.refresh()
            }
        }
    }
}
