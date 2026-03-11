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
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(alignment: .leading, spacing: 12) {
                ForEach(usageManager.providerStates) { state in
                    ProviderCardView(state: state)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.06))

            VStack(alignment: .leading, spacing: 8) {
                Text("Preferences")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.7)
                    .padding(.horizontal, 4)

                MenuSectionCard {
                    VStack(spacing: 0) {
                        MenuToggleRow(title: "Compact", isOn: $usageManager.isCompactMode, position: .top)

                        MenuRowSeparator()

                        MenuActionRow(title: "Check for Updates", position: .middle) {
                            updater.checkForUpdates()
                        }
                        .disabled(!checkForUpdatesVM.canCheckForUpdates)

                        MenuRowSeparator()

                        MenuActionRow(title: "Quit", position: .bottom) {
                            NSApplication.shared.terminate(nil)
                        }
                        .keyboardShortcut("q", modifiers: [.command])
                    }
                }
            }
        }
        .frame(width: 380)
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor).opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            Task {
                await usageManager.refresh()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("aizen")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                Text(usageManager.lastUpdatedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if usageManager.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 28, height: 28)
            } else {
                Button {
                    Task {
                        await usageManager.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .help("Refresh")
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}

private struct MenuActionRow: View {
    let title: String
    let position: MenuRowPosition
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(MenuRowBackground(position: position))
    }
}

private struct MenuToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let position: MenuRowPosition

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MenuRowBackground(position: position))
    }
}

private struct MenuSectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct MenuRowSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }
}

private enum MenuRowPosition {
    case top
    case middle
    case bottom

    var corners: RectangleCornerRadii {
        switch self {
        case .top:
            RectangleCornerRadii(topLeading: 10, bottomLeading: 0, bottomTrailing: 0, topTrailing: 10)
        case .middle:
            RectangleCornerRadii(topLeading: 0, bottomLeading: 0, bottomTrailing: 0, topTrailing: 0)
        case .bottom:
            RectangleCornerRadii(topLeading: 0, bottomLeading: 10, bottomTrailing: 10, topTrailing: 0)
        }
    }
}

private struct MenuRowBackground: View {
    let position: MenuRowPosition

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    var body: some View {
        UnevenRoundedRectangle(cornerRadii: position.corners, style: .continuous)
            .fill(backgroundColor)
            .onHover { hovering in
                isHovered = hovering
            }
    }

    private var backgroundColor: Color {
        guard isEnabled else {
            return Color.white.opacity(0.025)
        }

        return isHovered ? Color.white.opacity(0.09) : Color.clear
    }
}
