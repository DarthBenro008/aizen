import Foundation

actor CredentialManager {
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    var codexAuthURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("auth.json")
    }

    func codexCredentials() throws -> CodexTokens {
        let authFile = try loadCodexAuthFile()
        return authFile.tokens
    }

    func refreshCodexTokens() async throws -> CodexTokens {
        var authFile = try loadCodexAuthFile()

        guard !authFile.tokens.refreshToken.isEmpty else {
            throw ProviderError.notConfigured("Codex refresh token is missing in ~/.codex/auth.json")
        }

        guard let refreshURL = URL(string: "https://auth.openai.com/oauth/token") else {
            throw ProviderError.transport("Invalid OpenAI auth URL")
        }

        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": "app_EMoamEEZ73f0CkXaXp7hrann",
            "grant_type": "refresh_token",
            "refresh_token": authFile.tokens.refreshToken,
            "scope": "openid profile email"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw ProviderError.httpStatus(httpResponse.statusCode)
        }

        let refreshed = try decoder.decode(CodexRefreshResponse.self, from: data)
        let newRefreshToken = refreshed.refreshToken ?? authFile.tokens.refreshToken

        authFile.tokens = CodexTokens(
            accessToken: refreshed.accessToken,
            refreshToken: newRefreshToken,
            accountID: authFile.tokens.accountID
        )
        authFile.lastRefresh = Self.timestampString(for: Date())

        try saveCodexAuthFile(authFile)
        return authFile.tokens
    }

    func hasCodexCredentials() -> Bool {
        fileManager.fileExists(atPath: codexAuthURL.path)
    }

    func hasCopilotCLI() -> Bool {
        Self.ghPaths.contains(where: { fileManager.isExecutableFile(atPath: $0) })
    }

    func copilotToken() throws -> String {
        for ghPath in Self.ghPaths where fileManager.isExecutableFile(atPath: ghPath) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ghPath)
            process.arguments = ["auth", "token"]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                continue
            }

            if process.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let token = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                if !token.isEmpty {
                    return token
                }
            }
        }

        throw ProviderError.notConfigured("Run `gh auth login` so `gh auth token` returns a token")
    }

    private func loadCodexAuthFile() throws -> CodexAuthFile {
        guard fileManager.fileExists(atPath: codexAuthURL.path) else {
            throw ProviderError.notConfigured("Run `codex login` to create ~/.codex/auth.json")
        }

        let data = try Data(contentsOf: codexAuthURL)
        return try decoder.decode(CodexAuthFile.self, from: data)
    }

    private func saveCodexAuthFile(_ authFile: CodexAuthFile) throws {
        let data = try encoder.encode(authFile)
        try data.write(to: codexAuthURL, options: .atomic)
    }

    // MARK: - Claude Code

    static let claudePaths: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude"
        ]
    }()

    func hasClaudeCodeCLI() -> Bool {
        Self.claudePaths.contains(where: { fileManager.isExecutableFile(atPath: $0) })
    }

    func claudeAuthStatus() throws -> ClaudeAuthStatus {
        for claudePath in Self.claudePaths where fileManager.isExecutableFile(atPath: claudePath) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: claudePath)
            process.arguments = ["auth", "status"]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                continue
            }

            if process.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let status = try JSONDecoder().decode(ClaudeAuthStatus.self, from: outputData)
                return status
            }
        }

        throw ProviderError.notConfigured("Run `claude auth login` to sign in to your Anthropic account")
    }

    func claudeOAuthToken() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ProviderError.notConfigured("Claude Code OAuth token not found in Keychain")
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let raw = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)

        // The keychain entry stores nested JSON: { "claudeAiOauth": { "accessToken": "..." } }
        if let jsonData = raw.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let oauthObj = json["claudeAiOauth"] as? [String: Any],
           let token = oauthObj["accessToken"] as? String ?? oauthObj["access_token"] as? String {
            return token
        }

        // Otherwise treat the raw value as the token itself
        guard !raw.isEmpty else {
            throw ProviderError.notConfigured("Claude Code OAuth token is empty")
        }

        return raw
    }

    private static let ghPaths = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh"]

    private static func timestampString(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
