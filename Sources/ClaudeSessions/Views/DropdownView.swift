import SwiftUI

struct DropdownView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Theme.dividerStrong).frame(height: 1)
            tabs
            Rectangle().fill(Theme.dividerStrong).frame(height: 1)
            content
            Rectangle().fill(Theme.dividerStrong).frame(height: 1)
            footer
        }
        .frame(width: Theme.panelWidth)
        .background(Theme.panelBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.panelStroke, lineWidth: 1)
        )
        .padding(6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                ClaudeMark(color: Theme.claudeOrange, size: 18)
                Text("Claude Sessions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer(minLength: 0)
            workingBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var workingBadge: some View {
        if state.workingCount > 0 {
            HStack(spacing: 6) {
                Circle().fill(Theme.green).frame(width: 6, height: 6)
                Text("\(state.workingCount) working")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.greenBg)
            .clipShape(Capsule())
        }
    }

    private var tabs: some View {
        HStack(spacing: 4) {
            TabButton(title: "Sessions", isSelected: state.selectedTab == .sessions) {
                state.selectedTab = .sessions
            }
            TabButton(title: "Usage", isSelected: state.selectedTab == .usage) {
                state.selectedTab = .usage
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var content: some View {
        switch state.selectedTab {
        case .sessions: SessionsTabView()
        case .usage: UsageTabView()
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch state.selectedTab {
        case .sessions: SessionsFooterView()
        case .usage: UsageFooterView()
        }
    }
}

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            RoundedRectangle(cornerRadius: 1)
                .fill(isSelected ? Theme.claudeOrangeStroke : Color.clear)
                .frame(height: 2)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
