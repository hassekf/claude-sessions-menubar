import Foundation

enum JSONLParser {
    struct ParsedTranscript {
        var model: String?
        var cwd: String?
        var totalInputTokens: Int = 0
        var totalOutputTokens: Int = 0
        var totalCacheReadTokens: Int = 0
        var totalCacheWriteTokens: Int = 0
        var toolCallCount: Int = 0
        var lastToolName: String?
        var subagents: [Subagent] = []
        var lastTimestamp: Date?

        var totalTokens: Int { totalInputTokens + totalOutputTokens }

        static let empty = ParsedTranscript()
    }

    static func parse(url: URL) throws -> ParsedTranscript {
        let data = try Data(contentsOf: url)
        return parse(data: data)
    }

    static func parse(data: Data) -> ParsedTranscript {
        var result = ParsedTranscript()

        var pendingTasks: [String: (type: String, description: String)] = [:]
        var completedTaskIds: Set<String> = []

        let newline = UInt8(ascii: "\n")
        var start = data.startIndex
        while start < data.endIndex {
            let end = data[start...].firstIndex(of: newline) ?? data.endIndex
            let lineData = data[start..<end]
            start = end < data.endIndex ? data.index(after: end) : data.endIndex
            guard !lineData.isEmpty else { continue }

            guard let obj = try? JSONSerialization.jsonObject(with: Data(lineData)) as? [String: Any] else {
                continue
            }

            if result.cwd == nil, let cwd = obj["cwd"] as? String {
                result.cwd = cwd
            }

            if let ts = obj["timestamp"] as? String, let date = parseISODate(ts) {
                result.lastTimestamp = date
            }

            let message = obj["message"] as? [String: Any]
            let type = obj["type"] as? String

            if let message {
                if let model = message["model"] as? String {
                    result.model = model
                }
                if let usage = message["usage"] as? [String: Any] {
                    result.totalInputTokens += (usage["input_tokens"] as? Int) ?? 0
                    result.totalOutputTokens += (usage["output_tokens"] as? Int) ?? 0
                    result.totalCacheReadTokens += (usage["cache_read_input_tokens"] as? Int) ?? 0
                    result.totalCacheWriteTokens += (usage["cache_creation_input_tokens"] as? Int) ?? 0
                }
                if let content = message["content"] as? [[String: Any]] {
                    for block in content {
                        guard let blockType = block["type"] as? String else { continue }
                        if blockType == "tool_use" {
                            result.toolCallCount += 1
                            let name = (block["name"] as? String) ?? ""
                            result.lastToolName = name
                            if name == "Task" || name == "Agent" {
                                let id = (block["id"] as? String) ?? UUID().uuidString
                                let input = (block["input"] as? [String: Any]) ?? [:]
                                let subType = (input["subagent_type"] as? String) ?? "general-purpose"
                                let desc = (input["description"] as? String)
                                    ?? (input["prompt"] as? String)
                                    ?? ""
                                pendingTasks[id] = (subType, String(desc.prefix(60)))
                            }
                        } else if blockType == "tool_result" {
                            if let id = block["tool_use_id"] as? String {
                                completedTaskIds.insert(id)
                            }
                        }
                    }
                }
            }

            // user turns sometimes carry tool_result in their message.content too
            if type == "user", let message {
                if let content = message["content"] as? [[String: Any]] {
                    for block in content {
                        if block["type"] as? String == "tool_result",
                           let id = block["tool_use_id"] as? String {
                            completedTaskIds.insert(id)
                        }
                    }
                }
            }
        }

        result.subagents = pendingTasks.compactMap { id, info -> Subagent? in
            let active = !completedTaskIds.contains(id)
            guard active else { return nil }
            return Subagent(id: id, type: info.type, description: info.description, isActive: true)
        }
        .sorted { $0.type < $1.type }

        return result
    }

    private static func parseISODate(_ s: String) -> Date? {
        if let d = isoFractional.date(from: s) { return d }
        return isoPlain.date(from: s)
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
