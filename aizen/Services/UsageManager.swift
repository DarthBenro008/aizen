import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class UsageManager {
    var providerStates: [ProviderUsageState]
    var isRefreshing = false
    var lastUpdatedAt: Date?
    var isCompactMode: Bool {
        didSet { UserDefaults.standard.set(isCompactMode, forKey: "isCompactMode") }
    }

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

        isCompactMode = UserDefaults.standard.bool(forKey: "isCompactMode")
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
        updateWidgetData()
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

    private func updateWidgetData() {
        let widgetProviders = providerStates.map { state in
            WidgetProviderData(
                id: state.id,
                name: state.name,
                iconName: state.iconName,
                planType: state.planType,
                items: state.usageItems.map { item in
                    WidgetUsageItem(
                        id: item.id,
                        label: item.label,
                        usedPercent: item.usedPercent,
                        remaining: item.remaining,
                        resetsAt: item.resetsAt
                    )
                },
                summaryRemainingPercent: state.summaryRemainingPercent,
                errorMessage: state.errorMessage,
                configurationMessage: state.configurationMessage
            )
        }

        let widgetData = WidgetUsageData(
            providers: widgetProviders,
            lastUpdated: lastUpdatedAt ?? Date()
        )
        widgetData.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
