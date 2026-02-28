import Foundation

enum UsageStatus: Sendable {
    case ok
    case warning
    case critical

    static func fromUsedPercent(_ usedPercent: Double) -> UsageStatus {
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

struct UsageItem: Identifiable, Sendable {
    let id: String
    let label: String
    let usedPercent: Double
    let remaining: String?
    let resetsAt: Date?
    let status: UsageStatus
}

struct ProviderUsageState: Identifiable, Sendable {
    let id: String
    let name: String
    let iconName: String
    var planType: String?
    var usageItems: [UsageItem]
    var errorMessage: String?
    var configurationMessage: String?
    var summaryRemainingPercent: Int?

    var isConfigured: Bool {
        configurationMessage == nil
    }

    var hasError: Bool {
        errorMessage != nil
    }
}
