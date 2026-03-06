import SwiftUI

struct ProviderTitleView: View {
    let state: ProviderUsageState

    var body: some View {
        HStack(spacing: 8) {
            ProviderIconView(
                id: state.id,
                name: state.name,
                fallbackSystemImage: state.iconName
            )

            Text(state.name)
                .font(.headline)
        }
    }
}

private struct ProviderIconView: View {
    let id: String
    let name: String
    let fallbackSystemImage: String

    private var normalizedName: String {
        "\(id) \(name)".lowercased()
    }

    @ViewBuilder
    var body: some View {
        if normalizedName.contains("codex") {
            CodexBrandMark()
                .frame(width: 18, height: 18)
        } else if normalizedName.contains("github") || normalizedName.contains("copilot") {
            GitHubBrandMark()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: fallbackSystemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 18, height: 18)
        }
    }
}

private struct CodexBrandMark: View {
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .frame(width: 5, height: 13)
                    .offset(y: -4)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Circle()
                .fill(Color(nsColor: .windowBackgroundColor))
                .frame(width: 4, height: 4)
        }
        .foregroundStyle(.primary)
    }
}

private struct GitHubBrandMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary)

            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 7)
                    .offset(y: 1.5)

                Circle()
                    .fill(.white)
                    .frame(width: 3.5, height: 3.5)
                    .offset(x: -3.5, y: -4)

                Circle()
                    .fill(.white)
                    .frame(width: 3.5, height: 3.5)
                    .offset(x: 3.5, y: -4)

                Capsule(style: .continuous)
                    .fill(Color.primary)
                    .frame(width: 3, height: 6)
                    .offset(y: 4.5)
            }
        }
    }
}
