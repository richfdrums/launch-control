import Foundation
import Observation

struct RunRecord: Codable, Identifiable, Equatable {
    var id: UUID  // the run's log too (RunLogs)
    var date: Date
    var result: RunResult
}

/// The timed runs, newest first, in Documents/history.json.
@Observable @MainActor
final class History {
    private(set) var runs: [RunRecord] = []

    private static var url: URL { URL.documentsDirectory.appending(path: "history.json") }

    init() {
        runs = (try? JSONDecoder().decode([RunRecord].self, from: Data(contentsOf: Self.url))) ?? []
    }

    var best: RunRecord? { runs.min { $0.result.zeroToSixty < $1.result.zeroToSixty } }

    /// Keeps a run and its log; whether it's the best yet.
    func add(_ log: RunLog, _ result: RunResult) -> (RunRecord, Bool) {
        let isBest = best.map { result.zeroToSixty < $0.result.zeroToSixty } ?? true
        let record = RunRecord(id: log.id, date: log.date, result: result)
        do { try RunLogs.save(log) } catch { print("Couldn't save the run's log: \(error.localizedDescription)") }
        runs.insert(record, at: 0)
        save()
        return (record, isBest)
    }

    func delete(_ record: RunRecord) {
        RunLogs.delete(record.id)
        runs.removeAll { $0.id == record.id }
        save()
    }

    private func save() {
        do { try JSONEncoder().encode(runs).write(to: Self.url, options: .atomic) } catch {
            print("Couldn't save the history: \(error.localizedDescription)")
        }
    }
}
