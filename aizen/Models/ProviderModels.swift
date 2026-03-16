import Foundation

struct CodexAuthFile: Codable, Sendable {
    let authMode: String?
    var tokens: CodexTokens
    var lastRefresh: String?

    enum CodingKeys: String, CodingKey {
        case authMode = "auth_mode"
        case tokens
        case lastRefresh = "last_refresh"
    }
}

struct CodexTokens: Codable, Sendable {
    var accessToken: String
    var refreshToken: String
    let accountID: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case accountID = "account_id"
    }
}

struct CodexUsageResponse: Decodable, Sendable {
    let planType: String?
    let rateLimit: CodexRateLimit?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
    }
}

struct CodexRateLimit: Decodable, Sendable {
    let primaryWindow: CodexRateWindow?
    let secondaryWindow: CodexRateWindow?

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct CodexRateWindow: Decodable, Sendable {
    let usedPercent: Double
    let resetAt: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case resetAt = "reset_at"
    }
}

struct CodexRefreshResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct CopilotUserResponse: Decodable, Sendable {
    let copilotPlan: String?
    let quotaResetDateUTC: String?
    let quotaSnapshots: CopilotQuotaSnapshots?

    enum CodingKeys: String, CodingKey {
        case copilotPlan = "copilot_plan"
        case quotaResetDateUTC = "quota_reset_date_utc"
        case quotaSnapshots = "quota_snapshots"
    }
}

struct CopilotQuotaSnapshots: Decodable, Sendable {
    let premiumInteractions: CopilotQuotaSnapshot?

    enum CodingKeys: String, CodingKey {
        case premiumInteractions = "premium_interactions"
    }
}

struct CopilotQuotaSnapshot: Decodable, Sendable {
    let entitlement: Int?
    let remaining: Int?
    let percentRemaining: Double?
    let unlimited: Bool?

    enum CodingKeys: String, CodingKey {
        case entitlement
        case remaining
        case percentRemaining = "percent_remaining"
        case unlimited
    }
}

// MARK: - Claude Code

struct ClaudeAuthStatus: Decodable, Sendable {
    let loggedIn: Bool
    let authMethod: String?
    let apiProvider: String?
    let email: String?
    let orgId: String?
    let orgName: String?
    let subscriptionType: String?
}

struct ClaudeUsageResponse: Decodable, Sendable {
    let fiveHour: ClaudeUsageWindow?
    let sevenDay: ClaudeUsageWindow?
    let sevenDayOpus: ClaudeUsageWindow?
    let sevenDaySonnet: ClaudeUsageWindow?
    let extraUsage: ClaudeExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
        case extraUsage = "extra_usage"
    }

    /// Flexible initializer: decodes known fields, ignores unknown structure
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        fiveHour = try? container?.decode(ClaudeUsageWindow.self, forKey: .fiveHour)
        sevenDay = try? container?.decode(ClaudeUsageWindow.self, forKey: .sevenDay)
        sevenDayOpus = try? container?.decode(ClaudeUsageWindow.self, forKey: .sevenDayOpus)
        sevenDaySonnet = try? container?.decode(ClaudeUsageWindow.self, forKey: .sevenDaySonnet)
        extraUsage = try? container?.decode(ClaudeExtraUsage.self, forKey: .extraUsage)
    }
}

struct ClaudeUsageWindow: Decodable, Sendable {
    let utilization: Double
    let resetsAt: Date?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct ClaudeExtraUsage: Decodable, Sendable {
    let isEnabled: Bool?
    let monthlyLimit: Double?
    let usedCredits: Double?
    let utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}
