import Foundation

final class CopilotProvider: UsageProvider {
    let id = "copilot"
    let name = "GitHub Copilot"
    let iconName = "chevron.left.forwardslash.chevron.right"
    let summaryPrefix = "G"
    let configurationInstructions = "Run `gh auth login` so `gh auth token` returns a token"

    private let credentialManager: CredentialManager
    private(set) var planType: String?

    init(credentialManager: CredentialManager) {
        self.credentialManager = credentialManager
    }

    func isAvailable() -> Bool {
        let fileManager = FileManager.default
        return fileManager.isExecutableFile(atPath: "/opt/homebrew/bin/gh") || fileManager.isExecutableFile(atPath: "/usr/local/bin/gh")
    }

    func fetchUsage() async throws -> [UsageItem] {
        let token = try await credentialManager.copilotToken()

        guard let usageURL = URL(string: "https://api.github.com/copilot_internal/user") else {
            throw ProviderError.transport("Invalid Copilot usage URL")
        }

        var request = URLRequest(url: usageURL)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("vscode/1.96.2", forHTTPHeaderField: "Editor-Version")
        request.setValue("GitHubCopilotChat/0.26.7", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ProviderError.httpStatus(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(CopilotUserResponse.self, from: data)
        planType = decoded.copilotPlan?.capitalized

        let premium = decoded.quotaSnapshots?.premiumInteractions
        let percentRemaining = premium?.percentRemaining ?? 0
        let usedPercent = max(0, 100 - percentRemaining)

        let remainingText: String?
        if let entitlement = premium?.entitlement,
           let remaining = premium?.remaining,
           (premium?.unlimited ?? false) == false {
            remainingText = "\(remaining)/\(entitlement)"
        } else {
            remainingText = "Unlimited"
        }

        let resetDate = Self.parseDate(decoded.quotaResetDateUTC)

        return [
            UsageItem(
                id: "premium",
                label: "Premium Requests",
                usedPercent: usedPercent,
                remaining: remainingText,
                resetsAt: resetDate,
                status: UsageStatus.fromUsedPercent(usedPercent)
            )
        ]
    }

    func summaryRemainingPercent(from items: [UsageItem]) -> Int? {
        guard let premium = items.first else {
            return nil
        }
        let remaining = max(0, 100 - premium.usedPercent)
        return Int(remaining.rounded())
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: raw)
    }
}
