import Foundation
import SwiftData

@Model
final class Routine {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routine)
    var entries: [RoutineEntry] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }

    var sortedEntries: [RoutineEntry] {
        entries.sorted { $0.position < $1.position }
    }
}

@Model
final class RoutineEntry {
    var position: Int
    var targetSets: Int
    var targetReps: Int

    var routine: Routine?
    var exercise: Exercise?

    init(position: Int, targetSets: Int = 3, targetReps: Int = 10, exercise: Exercise?, routine: Routine? = nil) {
        self.position = position
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.exercise = exercise
        self.routine = routine
    }
}
