import Foundation

final class CodexProvider: UsageProvider {
    let id = "codex"
    let name = "GPT Codex"
    let iconName = "brain.head.profile"
    let summaryPrefix = "C"
    let configurationInstructions = "Run `codex login` to create ~/.codex/auth.json"

    private let credentialManager: CredentialManager
    private(set) var planType: String?

    init(credentialManager: CredentialManager) {
        self.credentialManager = credentialManager
    }

    func isAvailable() -> Bool {
        FileManager.default.fileExists(
            atPath: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".codex", isDirectory: true)
                .appendingPathComponent("auth.json").path
        )
    }

    func fetchUsage() async throws -> [UsageItem] {
        let tokens = try await credentialManager.codexCredentials()
        do {
            return try await fetchUsage(with: tokens)
        } catch ProviderError.httpStatus(let statusCode) where statusCode == 401 {
            let refreshed = try await credentialManager.refreshCodexTokens()
            return try await fetchUsage(with: refreshed)
        }
    }

    func summaryRemainingPercent(from items: [UsageItem]) -> Int? {
        guard let primary = items.first(where: { $0.id == "primary" }) else {
            return nil
        }
        let remaining = max(0, 100 - primary.usedPercent)
        return Int(remaining.rounded())
    }

    private func fetchUsage(with tokens: CodexTokens) async throws -> [UsageItem] {
        guard let usageURL = URL(string: "https://chatgpt.com/backend-api/wham/usage") else {
            throw ProviderError.transport("Invalid Codex usage URL")
        }

        var request = URLRequest(url: usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(tokens.accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        request.setValue("codex-cli", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ProviderError.httpStatus(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(CodexUsageResponse.self, from: data)
        planType = decoded.planType?.capitalized

        var items: [UsageItem] = []

        if let primary = decoded.rateLimit?.primaryWindow {
            items.append(
                UsageItem(
                    id: "primary",
                    label: "5h Limit",
                    usedPercent: primary.usedPercent,
                    remaining: nil,
                    resetsAt: primary.resetAt.map(Date.init(timeIntervalSince1970:)),
                    status: UsageStatus.fromUsedPercent(primary.usedPercent)
                )
            )
        }

        if let secondary = decoded.rateLimit?.secondaryWindow {
            items.append(
                UsageItem(
                    id: "secondary",
                    label: "Weekly Limit",
                    usedPercent: secondary.usedPercent,
                    remaining: nil,
                    resetsAt: secondary.resetAt.map(Date.init(timeIntervalSince1970:)),
                    status: UsageStatus.fromUsedPercent(secondary.usedPercent)
                )
            )
        }

        return items
    }
}
