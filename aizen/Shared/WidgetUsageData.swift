import Foundation

/// App Group identifier shared between the main app and widget extension.
/// On macOS, App Groups use the Team ID prefix format.
enum AppGroupConstants {
    /// The App Group suite name for shared UserDefaults.
    /// Uses `group.` prefix which works for both sandbox and non-sandbox macOS apps.
    static let suiteName = "group.com.benrostudios.aizen"

    /// UserDefaults key for the serialized widget data.
    static let widgetDataKey = "widgetUsageData"
}

/// Lightweight Codable snapshot of provider usage data,
/// written by the main app and read by the widget extension.
struct WidgetUsageData: Codable, Sendable {
    let providers: [WidgetProviderData]
    let lastUpdated: Date

    /// Convenience to read from shared UserDefaults.
    static func load() -> WidgetUsageData? {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName),
              let data = defaults.data(forKey: AppGroupConstants.widgetDataKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetUsageData.self, from: data)
    }

    /// Write to shared UserDefaults.
    func save() {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName),
              let data = try? JSONEncoder().encode(self) else {
            return
        }
        defaults.set(data, forKey: AppGroupConstants.widgetDataKey)
    }
}

/// A single provider's data for widget display.
struct WidgetProviderData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let iconName: String
    let planType: String?
    let items: [WidgetUsageItem]
    let summaryRemainingPercent: Int?
    let errorMessage: String?
    let configurationMessage: String?

    var isConfigured: Bool {
        configurationMessage == nil
    }

    var hasError: Bool {
        errorMessage != nil
    }
}

/// A single usage metric for widget display.
struct WidgetUsageItem: Codable, Sendable, Identifiable {
    let id: String
    let label: String
    let usedPercent: Double
    let remaining: String?
    let resetsAt: Date?

    var remainingPercent: Double {
        max(0, 100 - usedPercent)
    }

    var status: WidgetUsageStatus {
        WidgetUsageStatus.fromUsedPercent(usedPercent)
    }
}

/// Usage status for color coding in the widget.
enum WidgetUsageStatus: String, Codable, Sendable {
    case ok
    case warning
    case critical

    static func fromUsedPercent(_ usedPercent: Double) -> WidgetUsageStatus {
        switch usedPercent {
        case ..<50:
            return .ok
        case 50...80:
            return .warning
        default:
            return .critical
        }
    }
}
