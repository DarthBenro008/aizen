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
