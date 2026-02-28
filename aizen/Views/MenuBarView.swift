import AppKit
import SwiftUI

struct MenuBarView: View {
    let usageManager: UsageManager

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
