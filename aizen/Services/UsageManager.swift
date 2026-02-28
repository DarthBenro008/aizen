import Foundation
import Observation

@MainActor
@Observable
final class UsageManager {
    var providerStates: [ProviderUsageState]
    var isRefreshing = false
    var lastUpdatedAt: Date?

    private let providers: [any UsageProvider]

    init(
        credentialManager: CredentialManager = CredentialManager(),
        providers: [any UsageProvider]? = nil
    ) {
        if let providers {
            self.providers = providers
        } else {
            self.providers = [
                CodexProvider(credentialManager: credentialManager),
                CopilotProvider(credentialManager: credentialManager)
            ]
        }

        providerStates = self.providers.map {
            ProviderUsageState(
                id: $0.id,
                name: $0.name,
                iconName: $0.iconName,
                planType: nil,
                usageItems: [],
                errorMessage: nil,
                configurationMessage: nil,
                summaryRemainingPercent: nil
            )
        }
    }

    var menuBarSummaryText: String {
        let codex = providerStates.first(where: { $0.id == "codex" })?.summaryRemainingPercent
        let copilot = providerStates.first(where: { $0.id == "copilot" })?.summaryRemainingPercent

        let codexText = codex.map(String.init) ?? "--"
        let copilotText = copilot.map(String.init) ?? "--"
        return "C:\(codexText)% G:\(copilotText)%"
    }

    var lastUpdatedText: String {
        guard let lastUpdatedAt else {
            return "Last updated: never"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: lastUpdatedAt, relativeTo: Date())
        return "Last updated: \(relative)"
    }

    func refresh() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        for provider in providers {
            let state = await refreshState(for: provider)
            updateState(state)
        }

        lastUpdatedAt = Date()
    }

    private func refreshState(for provider: any UsageProvider) async -> ProviderUsageState {
        var state = ProviderUsageState(
            id: provider.id,
            name: provider.name,
            iconName: provider.iconName,
            planType: provider.planType,
            usageItems: [],
            errorMessage: nil,
            configurationMessage: nil,
            summaryRemainingPercent: nil
        )

        guard provider.isAvailable() else {
            state.configurationMessage = provider.configurationInstructions
            return state
        }

        do {
            let items = try await provider.fetchUsage()
            state.planType = provider.planType
            state.usageItems = items
            state.summaryRemainingPercent = provider.summaryRemainingPercent(from: items)
            return state
        } catch let error as ProviderError {
            switch error {
            case let .notConfigured(message):
                state.configurationMessage = message
            default:
                state.errorMessage = "⚠ Unable to fetch"
            }
            return state
        } catch {
            state.errorMessage = "⚠ Unable to fetch"
            return state
        }
    }

    private func updateState(_ newState: ProviderUsageState) {
        if let index = providerStates.firstIndex(where: { $0.id == newState.id }) {
            providerStates[index] = newState
        } else {
            providerStates.append(newState)
        }
    }
}
