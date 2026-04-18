import Foundation

enum SessionScanner {
    static let activeCutoff: TimeInterval = 30 * 60
    static let workingThreshold: TimeInterval = 2.0

    static var projectsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
    }

    static func scan() -> [Session] {
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return [] }

        let now = Date()
        let cutoff = now.addingTimeInterval(-activeCutoff)
        var sessions: [Session] = []

        for projectDir in projectDirs {
            let isDir = (try? projectDir.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDir else { continue }

            guard let files = try? fm.contentsOfDirectory(
                at: projectDir,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) else { continue }

            for file in files where file.pathExtension == "jsonl" {
                guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                      let mtime = values.contentModificationDate,
                      mtime > cutoff else { continue }

                let idleSeconds = Int(now.timeIntervalSince(mtime))
                let isWorking = now.timeIntervalSince(mtime) < workingThreshold

                let parsed = (try? JSONLParser.parse(url: file)) ?? .empty

                let decodedPath = parsed.cwd ?? decodeProjectPath(projectDir.lastPathComponent)
                let projectName: String = {
                    let name = (decodedPath as NSString).lastPathComponent
                    return name.isEmpty ? projectDir.lastPathComponent : name
                }()

                let session = Session(
                    id: file.deletingPathExtension().lastPathComponent,
                    projectPath: decodedPath,
                    projectName: projectName,
                    model: prettyModel(parsed.model),
                    modelTier: modelTier(parsed.model),
                    tokens: parsed.totalTokens,
                    toolCallCount: parsed.toolCallCount,
                    lastToolName: parsed.lastToolName,
                    lastActivity: mtime,
                    isWorking: isWorking,
                    idleSeconds: max(0, idleSeconds),
                    subagents: parsed.subagents,
                    transcriptURL: file
                )
                sessions.append(session)
            }
        }

        // Working first, then by most recent activity
        return sessions.sorted { lhs, rhs in
            if lhs.isWorking != rhs.isWorking { return lhs.isWorking }
            return lhs.lastActivity > rhs.lastActivity
        }
    }

    private static func decodeProjectPath(_ encoded: String) -> String {
        // Claude encodes paths by replacing '/' with '-'. This is lossy for
        // paths that contain '-' themselves; we accept the lossy decoding as
        // fallback when the transcript does not contain a cwd field.
        encoded.replacingOccurrences(of: "-", with: "/")
    }

    private static func prettyModel(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "—" }
        let lower = raw.lowercased()
        if lower.contains("opus-4-7") { return "Opus 4.7" }
        if lower.contains("opus-4-6") { return "Opus 4.6" }
        if lower.contains("opus-4") { return "Opus 4" }
        if lower.contains("opus") { return "Opus" }
        if lower.contains("sonnet-4-6") { return "Sonnet 4.6" }
        if lower.contains("sonnet-4-5") { return "Sonnet 4.5" }
        if lower.contains("sonnet") { return "Sonnet" }
        if lower.contains("haiku-4-5") { return "Haiku 4.5" }
        if lower.contains("haiku") { return "Haiku" }
        return raw
    }

    private static func modelTier(_ raw: String?) -> Session.ModelTier {
        guard let raw = raw?.lowercased() else { return .unknown }
        if raw.contains("opus") { return .opus }
        if raw.contains("sonnet") { return .sonnet }
        if raw.contains("haiku") { return .haiku }
        return .unknown
    }
}
