import Foundation

enum ProviderError: LocalizedError {
    case notConfigured(String)
    case transport(String)
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case let .notConfigured(message):
            return message
        case let .transport(message):
            return message
        case .invalidResponse:
            return "Invalid response from server"
        case let .httpStatus(statusCode):
            return "Unexpected status code: \(statusCode)"
        }
    }
}

protocol UsageProvider: Identifiable {
    var id: String { get }
    var name: String { get }
    var iconName: String { get }
    var planType: String? { get }
    var summaryPrefix: String { get }
    var configurationInstructions: String { get }

    func fetchUsage() async throws -> [UsageItem]
    func isAvailable() -> Bool
    func summaryRemainingPercent(from items: [UsageItem]) -> Int?
}

extension UsageProvider {
    func summaryRemainingPercent(from items: [UsageItem]) -> Int? {
        guard let first = items.first else {
            return nil
        }

        let remaining = max(0, 100 - first.usedPercent)
        return Int(remaining.rounded())
    }
}
