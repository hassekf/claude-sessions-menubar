import Foundation

/// Reads the authoritative per-session state written by the Claude Code
/// `claude-sessions-tracker` plugin at `~/.claude/sessions-state/<sid>.json`.
///
/// When the plugin is installed, its hook output is the source of truth for
/// `isWorking` (it flips on `UserPromptSubmit` / `PreToolUse` and off on
/// `Stop`, so "thinking" time is correctly counted as working).
/// When it is not installed, callers fall back to the mtime heuristic.
enum SessionStateReader {
    struct State {
        let sessionId: String
        let working: Bool
        let updatedAt: Date
        let workingSince: Date?
        let lastTool: String?
    }

    static var stateDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/sessions-state")
    }

    /// Returns true when the `claude-sessions-tracker` plugin is installed
    /// in Claude Code. When installed, the state file IS the source of
    /// truth — a session without a state file is considered ended, even if
    /// its JSONL was modified recently.
    static func isPluginInstalled() -> Bool {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/plugins/installed_plugins.json")
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let plugins = obj["plugins"] as? [String: Any] else { return false }
        return plugins.keys.contains { $0.hasPrefix("claude-sessions-tracker@") }
    }

    static func readAll() -> [String: State] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: stateDirectory,
            includingPropertiesForKeys: nil
        ) else { return [:] }

        var out: [String: State] = [:]
        for url in entries where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let sid = obj["session_id"] as? String else { continue }

            let working = (obj["working"] as? Bool) ?? false
            let updatedAt = Date(timeIntervalSince1970: (obj["updated_at"] as? Double) ?? 0)
            let workingSince: Date? = (obj["working_since"] as? Double).map {
                Date(timeIntervalSince1970: $0)
            }
            let lastTool = obj["last_tool"] as? String

            out[sid] = State(
                sessionId: sid,
                working: working,
                updatedAt: updatedAt,
                workingSince: workingSince,
                lastTool: lastTool
            )
        }
        return out
    }
}
