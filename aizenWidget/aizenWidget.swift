import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct UsageEntry: TimelineEntry {
    let date: Date
    let data: WidgetUsageData?
}

// MARK: - Timeline Provider

struct UsageProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> ()) {
        let entry = UsageEntry(date: Date(), data: WidgetUsageData.load() ?? .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> ()) {
        let entry = UsageEntry(date: Date(), data: WidgetUsageData.load())
        // Refresh in 15 minutes; main app also triggers reload on each fetch
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Placeholder Data

extension WidgetUsageData {
    static let placeholder = WidgetUsageData(
        providers: [
            WidgetProviderData(
                id: "codex",
                name: "GPT Codex",
                iconName: "brain.head.profile",
                planType: "Plus",
                items: [
                    WidgetUsageItem(id: "primary", label: "5h Limit", usedPercent: 28, remaining: nil, resetsAt: nil),
                    WidgetUsageItem(id: "secondary", label: "Weekly", usedPercent: 15, remaining: nil, resetsAt: nil)
                ],
                summaryRemainingPercent: 72,
                errorMessage: nil,
                configurationMessage: nil
            ),
            WidgetProviderData(
                id: "copilot",
                name: "GitHub Copilot",
                iconName: "chevron.left.forwardslash.chevron.right",
                planType: "Pro",
                items: [
                    WidgetUsageItem(id: "premium", label: "Premium", usedPercent: 15, remaining: "850/1000", resetsAt: nil)
                ],
                summaryRemainingPercent: 85,
                errorMessage: nil,
                configurationMessage: nil
            )
        ],
        lastUpdated: Date()
    )
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let data: WidgetUsageData?

    var body: some View {
        if let data, !data.providers.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("aizen")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                ForEach(data.providers) { provider in
                    SmallProviderRow(provider: provider)
                }

                Spacer(minLength: 0)

                Text(relativeTimeText(data.lastUpdated))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Open aizen to sync")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SmallProviderRow: View {
    let provider: WidgetProviderData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: provider.iconName)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(provider.name)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                Spacer()
                if let pct = provider.summaryRemainingPercent {
                    Text("\(pct)%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colorForPercent(Double(pct)))
                }
            }

            if let item = provider.items.first {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.primary.opacity(0.1))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForPercent(item.remainingPercent))
                            .frame(width: geo.size.width * item.remainingPercent / 100)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let data: WidgetUsageData?

    var body: some View {
        if let data, !data.providers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("aizen — AI Usage")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(relativeTimeText(data.lastUpdated))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 12) {
                    ForEach(data.providers) { provider in
                        MediumProviderCard(provider: provider)
                    }
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Open aizen to sync usage data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MediumProviderCard: View {
    let provider: WidgetProviderData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: provider.iconName)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(provider.name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }

            if !provider.isConfigured {
                Text("Not configured")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if provider.hasError {
                Text("Unable to fetch")
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else {
                ForEach(provider.items) { item in
                    MediumUsageRow(item: item)
                }
            }

            Spacer(minLength: 0)

            if let pct = provider.summaryRemainingPercent {
                HStack {
                    Spacer()
                    Text("\(pct)% left")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(colorForPercent(Double(pct)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MediumUsageRow: View {
    let item: WidgetUsageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Spacer()
                if let remaining = item.remaining {
                    Text(remaining)
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(Int(item.remainingPercent.rounded()))% left")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForPercent(item.remainingPercent))
                        .frame(width: geo.size.width * item.remainingPercent / 100)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Helpers

private func colorForPercent(_ remaining: Double) -> Color {
    switch remaining {
    case 50...:
        return .green
    case 20..<50:
        return .yellow
    default:
        return .red
    }
}

private func relativeTimeText(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

// MARK: - Widget Definition

struct aizenWidget: Widget {
    let kind: String = "aizenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsageProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AI Usage")
        .description("See remaining AI subscription limits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetEntryView: View {
    var entry: UsageEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    aizenWidget()
} timeline: {
    UsageEntry(date: Date(), data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    aizenWidget()
} timeline: {
    UsageEntry(date: Date(), data: .placeholder)
}

#Preview("Empty", as: .systemSmall) {
    aizenWidget()
} timeline: {
    UsageEntry(date: Date(), data: nil)
}
