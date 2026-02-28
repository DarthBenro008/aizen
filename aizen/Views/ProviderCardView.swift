import SwiftUI

struct ProviderCardView: View {
    let state: ProviderUsageState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(state.name, systemImage: state.iconName)
                    .font(.headline)

                Spacer(minLength: 8)

                if let planType = state.planType, !planType.isEmpty {
                    Text(planType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let configurationMessage = state.configurationMessage {
                Text("Not configured")
                    .font(.subheadline.weight(.semibold))
                Text(configurationMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let errorMessage = state.errorMessage {
                Text(errorMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
            } else if state.usageItems.isEmpty {
                Text("No usage data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(state.usageItems) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.label)
                                .font(.subheadline)

                            Spacer(minLength: 8)

                            Text("\(Int(item.usedPercent.rounded()))% used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        UsageBarView(usedPercent: item.usedPercent, status: item.status)

                        HStack {
                            if let remaining = item.remaining {
                                Text("Remaining: \(remaining)")
                            } else {
                                Text("Remaining: \(Int(max(0, (100 - item.usedPercent).rounded())))%")
                            }

                            Spacer(minLength: 8)

                            if let resetDate = item.resetsAt {
                                Text("Resets \(resetDate, style: .relative)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
