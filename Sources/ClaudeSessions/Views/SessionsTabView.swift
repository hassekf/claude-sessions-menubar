import SwiftUI

struct SessionsTabView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        if state.sessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(state.sessions.enumerated()), id: \.element.id) { index, session in
                        SessionRowView(session: session)
                        if !session.subagents.isEmpty {
                            SubagentGroupView(subagents: session.subagents)
                        }
                        if index < state.sessions.count - 1 {
                            Rectangle().fill(Theme.dividerSoft).frame(height: 1)
                        }
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ClaudeMark(color: Theme.textTertiary, size: 28)
            Text("Nenhuma sessão ativa")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            Text("Abra o Claude Code em algum projeto")
                .font(.system(size: 11))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
