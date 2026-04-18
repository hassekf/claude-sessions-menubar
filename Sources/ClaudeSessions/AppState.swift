import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var usage: UsageSnapshot?
    @Published var usageError: String?
    @Published var selectedTab: Tab = .sessions
    @Published var subscriptionType: String?

    enum Tab: String, CaseIterable {
        case sessions, usage
    }

    enum StatusColor {
        case idle, working, allWorking
    }

    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.subscriptionType = CredentialsReader.read()?.subscriptionType
        scanSessions()
        Task { await self.fetchUsage() }
        startTimers()
    }

    private func startTimers() {
        Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in self?.scanSessions() }
            }
            .store(in: &cancellables)

        Timer.publish(every: 180, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in await self?.fetchUsage() }
            }
            .store(in: &cancellables)
    }

    func scanSessions() {
        let scanned = SessionScanner.scan()
        if scanned != sessions {
            sessions = scanned
        }
    }

    func fetchUsage(force: Bool = false) async {
        do {
            usage = try await UsageFetcher.shared.fetch(force: force)
            usageError = nil
        } catch {
            usageError = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        }
    }

    // Derived state
    var workingCount: Int { sessions.filter(\.isWorking).count }
    var totalCount: Int { sessions.count }
    var totalTokens: Int { sessions.reduce(0) { $0 + $1.tokens } }
    var activeSubagentsCount: Int { sessions.reduce(0) { $0 + $1.subagents.count } }

    var statusColor: StatusColor {
        if totalCount == 0 { return .idle }
        if workingCount == 0 { return .idle }
        if workingCount == totalCount { return .allWorking }
        return .working
    }
}
