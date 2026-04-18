import SwiftUI

struct UsageTabView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Group {
            if let usage = state.usage {
                ScrollView {
                    VStack(spacing: 0) {
                        UsageBarRow(
                            icon: "hourglass",
                            iconColor: Theme.claudeOrange,
                            label: "Sessão atual (5h)",
                            utilization: usage.fiveHour.utilization,
                            fillColor: Theme.claudeOrangeStroke,
                            resetsAt: usage.fiveHour.resetsAt,
                            resetPrefix: "Reseta"
                        )
                        Rectangle().fill(Theme.dividerSoft).frame(height: 1)
                        UsageBarRow(
                            icon: "calendar",
                            iconColor: Theme.blue,
                            label: "Semanal (7d)",
                            utilization: usage.sevenDay.utilization,
                            fillColor: Theme.blue,
                            resetsAt: usage.sevenDay.resetsAt,
                            resetPrefix: "Reseta"
                        )
                        modelBreakdown(usage: usage)
                        if let extra = usage.extraUsage {
                            Rectangle().fill(Theme.dividerSoft).frame(height: 1)
                            ExtraUsageRow(extra: extra)
                        }
                    }
                }
                .frame(maxHeight: 420)
            } else if let err = state.usageError {
                errorState(err)
            } else {
                loadingState
            }
        }
    }

    @ViewBuilder
    private func modelBreakdown(usage: UsageSnapshot) -> some View {
        if usage.sevenDaySonnet != nil || usage.sevenDayOpus != nil {
            Rectangle().fill(Theme.dividerSoft).frame(height: 1)
            VStack(alignment: .leading, spacing: 10) {
                Text("POR MODELO (7d)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(0.5)
                if let sonnet = usage.sevenDaySonnet {
                    ModelRow(
                        name: "Sonnet",
                        utilization: sonnet.utilization,
                        color: Theme.blue
                    )
                }
                if let opus = usage.sevenDayOpus {
                    ModelRow(
                        name: "Opus",
                        utilization: opus.utilization,
                        color: Theme.claudeOrange
                    )
                } else {
                    ModelRow(
                        name: "Opus",
                        utilization: 0,
                        color: Theme.claudeOrange
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView().scaleEffect(0.7)
            Text("Carregando usage…")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorState(_ err: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(Theme.claudeOrange)
                .font(.system(size: 16))
            Text(err)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Tentar novamente") {
                Task { await state.fetchUsage(force: true) }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.claudeOrange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
    }
}

struct UsageBarRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let utilization: Double
    let fillColor: Color
    let resetsAt: Date?
    let resetPrefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundColor(iconColor)
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer(minLength: 0)
                Text("\(Int(normalized.rounded()))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }
            ProgressBar(progress: normalized / 100, color: fillColor)
            if let resetString {
                Text(resetString)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var normalized: Double {
        utilization > 1 ? utilization : utilization * 100
    }

    private var resetString: String? {
        guard let resetsAt else { return nil }
        let delta = resetsAt.timeIntervalSinceNow
        if delta <= 0 { return "\(resetPrefix) agora" }
        let f = DateComponentsFormatter()
        f.unitsStyle = .abbreviated
        f.allowedUnits = [.day, .hour, .minute]
        f.maximumUnitCount = 2
        let str = f.string(from: delta) ?? "—"
        return "\(resetPrefix) em \(str)"
    }
}

struct ModelRow: View {
    let name: String
    let utilization: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer(minLength: 0)
                Text("\(Int(normalized.rounded()))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            ProgressBar(progress: normalized / 100, color: color, height: 4)
        }
    }

    private var normalized: Double {
        utilization > 1 ? utilization : utilization * 100
    }
}

struct ExtraUsageRow: View {
    let extra: UsageSnapshot.ExtraUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.green)
                    Text("Extra usage")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Text(extra.isEnabled ? "ON" : "OFF")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(extra.isEnabled ? Theme.green : Theme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(extra.isEnabled ? Theme.greenBg : Color.white.opacity(0.05))
                    .cornerRadius(3)
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(extra.currencySymbol)\(formatMoney(extra.usedCreditsMajor))")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                Text("/ \(extra.currencySymbol)\(formatMoney(extra.monthlyLimitMajor))")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            ProgressBar(progress: normalized / 100, color: Theme.green)
            Text("\(Int(normalized.rounded()))% usado · pay-as-you-go \(extra.isEnabled ? "ativo" : "inativo")")
                .font(.system(size: 11))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var normalized: Double {
        extra.utilization > 1 ? extra.utilization : extra.utilization * 100
    }

    private func formatMoney(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.locale = Locale(identifier: "pt_BR")
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
