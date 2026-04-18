import Foundation

actor UsageFetcher {
    static let shared = UsageFetcher()

    private let cacheTTL: TimeInterval = 180
    private let minInterval: TimeInterval = 30
    private var lastFetch: Date?
    private var cached: UsageSnapshot?

    enum UsageError: LocalizedError {
        case noCredentials
        case rateLimited
        case httpError(Int)
        case decoding

        var errorDescription: String? {
            switch self {
            case .noCredentials: return "OAuth token não encontrado"
            case .rateLimited: return "Rate limit atingido"
            case .httpError(let code): return "HTTP \(code)"
            case .decoding: return "Falha ao decodificar resposta"
            }
        }
    }

    func fetch(force: Bool = false) async throws -> UsageSnapshot {
        let now = Date()
        if !force, let cached, let last = lastFetch, now.timeIntervalSince(last) < cacheTTL {
            return cached
        }
        if let last = lastFetch, now.timeIntervalSince(last) < minInterval, let cached {
            return cached
        }

        guard let creds = CredentialsReader.read() else {
            throw UsageError.noCredentials
        }

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("ClaudeSessionsMenuBar/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw UsageError.httpError(-1)
        }
        switch http.statusCode {
        case 200: break
        case 429: throw UsageError.rateLimited
        default: throw UsageError.httpError(http.statusCode)
        }

        let decoded: UsageResponse
        do {
            decoded = try JSONDecoder().decode(UsageResponse.self, from: data)
        } catch {
            throw UsageError.decoding
        }

        let snapshot = decoded.toSnapshot()
        self.cached = snapshot
        self.lastFetch = Date()
        return snapshot
    }

    private struct UsageResponse: Decodable {
        let five_hour: Window
        let seven_day: Window
        let seven_day_sonnet: Window?
        let seven_day_opus: Window?
        let extra_usage: ExtraUsage?

        struct Window: Decodable {
            let utilization: Double
            let resets_at: String?
        }

        struct ExtraUsage: Decodable {
            let is_enabled: Bool
            let monthly_limit: Double?
            let used_credits: Double?
            let utilization: Double?
            let currency: String?
        }

        func toSnapshot() -> UsageSnapshot {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoPlain = ISO8601DateFormatter()
            isoPlain.formatOptions = [.withInternetDateTime]
            func date(_ s: String?) -> Date? {
                guard let s else { return nil }
                return iso.date(from: s) ?? isoPlain.date(from: s)
            }

            func window(_ w: Window?) -> UsageSnapshot.Window? {
                guard let w else { return nil }
                return .init(utilization: w.utilization, resetsAt: date(w.resets_at))
            }

            let extra: UsageSnapshot.ExtraUsage? = extra_usage.map {
                .init(
                    isEnabled: $0.is_enabled,
                    monthlyLimit: $0.monthly_limit ?? 0,
                    usedCredits: $0.used_credits ?? 0,
                    utilization: $0.utilization ?? 0,
                    currency: $0.currency ?? "USD"
                )
            }

            return UsageSnapshot(
                fiveHour: .init(utilization: five_hour.utilization, resetsAt: date(five_hour.resets_at)),
                sevenDay: .init(utilization: seven_day.utilization, resetsAt: date(seven_day.resets_at)),
                sevenDaySonnet: window(seven_day_sonnet),
                sevenDayOpus: window(seven_day_opus),
                extraUsage: extra,
                fetchedAt: Date()
            )
        }
    }
}
