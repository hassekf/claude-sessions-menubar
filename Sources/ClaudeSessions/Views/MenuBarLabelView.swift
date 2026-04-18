import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 4) {
            ClaudeMarkTemplateImage(size: 15)
            Text(countText)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
    }

    private var countText: String {
        state.totalCount == 0 ? "—" : "\(state.workingCount)/\(state.totalCount)"
    }
}
