import Foundation

struct UsageSnapshot: Equatable {
    let fiveHour: Window
    let sevenDay: Window
    let sevenDaySonnet: Window?
    let sevenDayOpus: Window?
    let extraUsage: ExtraUsage?
    let fetchedAt: Date

    struct Window: Equatable {
        let utilization: Double   // 0.0–100.0 from API
        let resetsAt: Date?
    }

    struct ExtraUsage: Equatable {
        let isEnabled: Bool
        let monthlyLimit: Double   // stored in minor units (cents/centavos)
        let usedCredits: Double    // stored in minor units
        let utilization: Double
        let currency: String       // e.g. "BRL", "USD"

        var monthlyLimitMajor: Double { monthlyLimit / 100 }
        var usedCreditsMajor: Double { usedCredits / 100 }

        var currencySymbol: String {
            switch currency.uppercased() {
            case "USD": return "$"
            case "BRL": return "R$"
            case "EUR": return "€"
            case "GBP": return "£"
            default: return currency + " "
            }
        }
    }
}
