import SwiftUI

struct SubagentGroupView: View {
    let subagents: [Subagent]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SUBAGENTS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
                .tracking(0.5)
            ForEach(subagents) { sub in
                HStack(spacing: 10) {
                    Image(systemName: iconFor(sub.type))
                        .font(.system(size: 11))
                        .foregroundColor(colorFor(sub.type))
                        .frame(width: 12, height: 12)
                    Text(sub.type)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    if !sub.description.isEmpty {
                        Text("· \(sub.description)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Circle().fill(Theme.green).frame(width: 6, height: 6)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.leading, 36)
        .padding(.trailing, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.2))
    }

    private func iconFor(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("explore") { return "magnifyingglass" }
        if t.contains("plan") { return "map" }
        if t.contains("review") { return "checkmark.shield" }
        if t.contains("status") { return "list.bullet.clipboard" }
        return "chevron.left.forwardslash.chevron.right"
    }

    private func colorFor(_ type: String) -> Color {
        let t = type.lowercased()
        if t.contains("explore") { return Theme.blue }
        if t.contains("plan") { return Theme.claudeOrange }
        if t.contains("review") { return Theme.green }
        return Theme.purple
    }
}
