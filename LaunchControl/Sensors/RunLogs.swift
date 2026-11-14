import Foundation

/// Each run's raw sensor data, in Documents/Runs. The Files app shows the app's Documents
/// (Base.xcconfig), so a run can be shared and analysed again.
enum RunLogs {
    static var folder: URL { URL.documentsDirectory.appending(path: "Runs", directoryHint: .isDirectory) }

    static func url(_ id: UUID) -> URL { folder.appending(path: "\(id.uuidString).json") }

    static func save(_ log: RunLog) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try JSONEncoder().encode(log).write(to: url(log.id), options: .atomic)
    }

    static func load(_ id: UUID) throws -> RunLog {
        try JSONDecoder().decode(RunLog.self, from: Data(contentsOf: url(id)))
    }

    static func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: url(id))
    }
}
