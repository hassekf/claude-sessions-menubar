import Foundation

struct Session: Identifiable, Equatable {
    let id: String
    let projectPath: String
    let projectName: String
    let model: String
    let modelTier: ModelTier
    let tokens: Int
    let toolCallCount: Int
    let lastToolName: String?
    let lastActivity: Date
    let isWorking: Bool
    let idleSeconds: Int
    let subagents: [Subagent]
    let transcriptURL: URL

    enum ModelTier: String, Equatable {
        case opus, sonnet, haiku, unknown
    }
}

struct Subagent: Identifiable, Equatable {
    let id: String
    let type: String
    let description: String
    let isActive: Bool
}
