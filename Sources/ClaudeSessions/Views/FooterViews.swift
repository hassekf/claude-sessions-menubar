import SwiftUI
import AppKit

struct SessionsFooterView: View {
    @EnvironmentObject var state: AppState
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled

    var body: some View {
        HStack(spacing: 14) {
            stat(icon: "bolt.horizontal", value: tokensText, label: "tokens")
            stat(icon: "tree", value: "\(state.activeSubagentsCount)", label: "subagents")
            Spacer(minLength: 0)
            Menu {
                Toggle("Iniciar no login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        LaunchAtLogin.isEnabled = newValue
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
                ))
                Divider()
                Button("Sair") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.1))
    }

    private func stat(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.87))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textTertiary)
        }
    }

    private var tokensText: String {
        let t = state.totalTokens
        let k = Double(t) / 1000
        if k >= 1000 { return String(format: "%.1fM", k / 1000) }
        if k >= 1 { return String(format: "%.1fk", k) }
        return "\(t)"
    }
}

struct UsageFooterView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
                .foregroundColor(Theme.textTertiary)
            Text(statusText)
                .font(.system(size: 10))
                .foregroundColor(Theme.textTertiary)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let sub = state.subscriptionType, !sub.isEmpty {
                Text(sub.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.claudeOrange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Theme.claudeOrangeBg)
                    .cornerRadius(3)
            }
            Button {
                Task { await state.fetchUsage(force: true) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Atualizar agora")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.1))
    }

    private var statusText: String {
        if state.usageError != nil { return "oauth/usage · erro" }
        guard let usage = state.usage else { return "oauth/usage · cache 3 min" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return "atualizado \(f.localizedString(for: usage.fetchedAt, relativeTo: Date()))"
    }
}
