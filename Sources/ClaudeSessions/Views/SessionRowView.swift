import SwiftUI
import AppKit

struct SessionRowView: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            statusDot
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(session.projectName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(session.isWorking ? Theme.textPrimary : Color.white.opacity(0.87))
                    modelPill
                }
                activityLine
            }
            Spacer(minLength: 6)
            metrics
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(session.isWorking ? Color.white.opacity(0.03) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            openProject()
        }
    }

    private var statusDot: some View {
        Circle()
            .fill(session.isWorking ? Theme.green : Theme.idleGray)
            .frame(width: 10, height: 10)
            .shadow(color: session.isWorking ? Theme.green.opacity(0.6) : .clear, radius: 3, x: 0, y: 0)
    }

    private var modelPill: some View {
        let color: Color = {
            switch session.modelTier {
            case .opus: return Theme.claudeOrange
            case .sonnet: return Theme.blueText
            case .haiku: return Theme.green
            case .unknown: return Theme.textSecondary
            }
        }()
        let bg: Color = {
            switch session.modelTier {
            case .opus: return Theme.claudeOrangeBg
            case .sonnet: return Theme.blueBg
            case .haiku: return Theme.greenBg
            case .unknown: return Color.white.opacity(0.1)
            }
        }()
        return Text(session.model)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(bg)
            .cornerRadius(4)
    }

    private var activityLine: some View {
        HStack(spacing: 6) {
            Image(systemName: session.isWorking ? "terminal" : "clock")
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
            Text(activityText)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
        }
    }

    private var activityText: String {
        if session.isWorking {
            var parts: [String] = []
            if let tool = session.lastToolName, !tool.isEmpty {
                parts.append("Running \(tool)")
            } else {
                parts.append("Working")
            }
            if !session.subagents.isEmpty {
                let n = session.subagents.count
                parts.append("\(n) \(n == 1 ? "subagent" : "subagents")")
            }
            return parts.joined(separator: " · ")
        } else {
            if let tool = session.lastToolName, !tool.isEmpty {
                return "Idle · última ferramenta: \(tool)"
            }
            return "Idle · aguardando input"
        }
    }

    private var metrics: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if session.isWorking {
                Text(tokensFormatted)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                Text("tokens")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
            } else {
                Text(durationFormatted)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.8))
                Text("idle")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }

    private var tokensFormatted: String {
        let k = Double(session.tokens) / 1000
        if k >= 1000 { return String(format: "%.1fM", k / 1000) }
        if k >= 1 { return String(format: "%.1fk", k) }
        return "\(session.tokens)"
    }

    private var durationFormatted: String {
        let s = session.idleSeconds
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        let h = s / 3600
        let m = (s % 3600) / 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    private func openProject() {
        let url = URL(fileURLWithPath: session.projectPath)
        NSWorkspace.shared.open(url)
    }
}
