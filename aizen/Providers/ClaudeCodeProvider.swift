import Foundation
import os

final class ClaudeCodeProvider: UsageProvider {
    let id = "claude_code"
    let name = "Claude Code"
    let iconName = "sparkle"
    let summaryPrefix = "A"
    let configurationInstructions = "Run `claude auth login` to sign in to your Anthropic account"

    private let credentialManager: CredentialManager
    private(set) var planType: String?
    private let logger = Logger(subsystem: "com.aizen", category: "ClaudeCodeProvider")

    init(credentialManager: CredentialManager) {
        self.credentialManager = credentialManager
    }

    func isAvailable() -> Bool {
        let fileManager = FileManager.default
        return Self.claudePaths.contains(where: { fileManager.isExecutableFile(atPath: $0) })
    }

    func fetchUsage() async throws -> [UsageItem] {
        let authStatus = try await credentialManager.claudeAuthStatus()

        guard authStatus.loggedIn else {
            throw ProviderError.notConfigured(configurationInstructions)
        }

        planType = authStatus.subscriptionType?.capitalized

        let token = try await credentialManager.claudeOAuthToken()

        guard let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage") else {
            throw ProviderError.transport("Invalid Claude usage URL")
        }

        var request = URLRequest(url: usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("aizen/1.0 (macOS)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }

        // Log raw response for debugging/discovery
        if let rawJSON = String(data: data, encoding: .utf8) {
            logger.info("Claude usage API response (\(httpResponse.statusCode)): \(rawJSON)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Fallback: return subscription status only
            return fallbackItems(from: authStatus)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ClaudeUsageResponse.self, from: data)
        var items: [UsageItem] = []

        if let session = decoded.fiveHour {
            items.append(
                UsageItem(
                    id: "session",
                    label: "Session (5h)",
                    usedPercent: session.utilization,
                    remaining: Self.remainingLabel(session.utilization),
                    resetsAt: session.resetsAt,
                    status: UsageStatus.fromUsedPercent(session.utilization)
                )
            )
        }

        if let weekly = decoded.sevenDay {
            items.append(
                UsageItem(
                    id: "weekly",
                    label: "Weekly",
                    usedPercent: weekly.utilization,
                    remaining: Self.remainingLabel(weekly.utilization),
                    resetsAt: weekly.resetsAt,
                    status: UsageStatus.fromUsedPercent(weekly.utilization)
                )
            )
        }

        // If we got a response but couldn't extract structured data, use fallback
        if items.isEmpty {
            return fallbackItems(from: authStatus)
        }

        return items
    }

    private func fallbackItems(from authStatus: ClaudeAuthStatus) -> [UsageItem] {
        let label = authStatus.subscriptionType.map { "\($0.capitalized) Plan" } ?? "Signed In"
        return [
            UsageItem(
                id: "status",
                label: label,
                usedPercent: 0,
                remaining: "Active",
                resetsAt: nil,
                status: .ok
            )
        ]
    }

    private static func remainingLabel(_ utilization: Double) -> String {
        let remaining = max(0, 100 - utilization)
        return "\(Int(remaining))% remaining"
    }

    private static let claudePaths: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude"
        ]
    }()
}
