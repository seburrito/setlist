import Foundation
import SwiftData
import SwiftUI

@Model
final class Workout {
    var name: String
    var startedAt: Date
    var endedAt: Date?
    var pausedDuration: TimeInterval

    var routine: Routine?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var workoutExercises: [WorkoutExercise] = []

    init(name: String, startedAt: Date = .now, routine: Routine? = nil) {
        self.name = name
        self.startedAt = startedAt
        self.pausedDuration = 0
        self.routine = routine
    }

    var isFinished: Bool { endedAt != nil }

    var sortedExercises: [WorkoutExercise] {
        workoutExercises.sorted { $0.position < $1.position }
    }

    var duration: TimeInterval {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    var completedSets: [WorkoutSet] {
        workoutExercises.flatMap(\.sets).filter(\.done)
    }

    var totalVolume: Double {
        completedSets.reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }
    }

    var totalSetsDone: Int { completedSets.count }

    /// Coarse split classification, used for the calendar dot color and history list.
    /// Falls back to matching on exercise muscle tags when the workout has no routine.
    var splitKind: SplitKind {
        if let routineName = routine?.name {
            return SplitKind(routineName: routineName)
        }
        let tags = Set(workoutExercises.compactMap { $0.exercise?.muscleGroups }.flatMap { $0 })
        if tags.contains("Quads") || tags.contains("Hamstrings") || tags.contains("Glutes") || tags.contains("Calves") {
            return .legs
        }
        if tags.contains("Back") || tags.contains("Biceps") {
            return .pull
        }
        if tags.contains("Chest") || tags.contains("Shoulders") || tags.contains("Triceps") {
            return .push
        }
        return .other
    }
}

enum SplitKind {
    case push, pull, legs, other

    init(routineName: String) {
        let lower = routineName.lowercased()
        if lower.contains("push") { self = .push }
        else if lower.contains("pull") { self = .pull }
        else if lower.contains("leg") { self = .legs }
        else { self = .other }
    }

    var label: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .other: return "Other"
        }
    }

    var color: Color {
        switch self {
        case .push: return Theme.accent
        case .pull: return Theme.splitPull
        case .legs: return Theme.splitLegs
        case .other: return Theme.splitOther
        }
    }
}

@Model
final class WorkoutExercise {
    var position: Int
    /// Free-text "which machine/brand" note, ghosted from the last time this exercise was logged.
    var machineNote: String

    var exercise: Exercise?
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet] = []

    init(position: Int, exercise: Exercise?, machineNote: String = "", workout: Workout? = nil) {
        self.position = position
        self.exercise = exercise
        self.machineNote = machineNote
        self.workout = workout
    }

    var sortedSets: [WorkoutSet] {
        sets.sorted { $0.position < $1.position }
    }

    var isAllDone: Bool {
        !sets.isEmpty && sets.allSatisfy(\.done)
    }

    var doneCount: Int { sets.filter(\.done).count }

    var tagLine: String {
        let base = exercise?.tagLine ?? ""
        guard !machineNote.isEmpty else { return base }
        return base.isEmpty ? machineNote : base + " · " + machineNote
    }
}

enum SetType: String, Codable {
    case warmup, working, drop
}

@Model
final class WorkoutSet {
    var position: Int
    var weight: Double?
    var reps: Int?
    /// Last session's values for this slot, shown as greyed "ghost" placeholder text
    /// until the user logs a real value.
    var ghostWeight: Double
    var ghostReps: Int
    var setTypeRaw: String
    var done: Bool
    var completedAt: Date?

    var workoutExercise: WorkoutExercise?

    init(position: Int, ghostWeight: Double, ghostReps: Int, setType: SetType = .working) {
        self.position = position
        self.ghostWeight = ghostWeight
        self.ghostReps = ghostReps
        self.setTypeRaw = setType.rawValue
        self.done = false
    }

    var setType: SetType {
        get { SetType(rawValue: setTypeRaw) ?? .working }
        set { setTypeRaw = newValue.rawValue }
    }

    /// The value to display: the logged one once the user has entered/completed it,
    /// otherwise the ghost placeholder.
    var displayWeight: Double { weight ?? ghostWeight }
    var displayReps: Int { reps ?? ghostReps }
    var isFilled: Bool { weight != nil || done }

    /// Estimated 1-rep max via the Epley formula.
    var estimated1RM: Double {
        let w = displayWeight, r = Double(displayReps)
        return r <= 1 ? w : w * (1 + r / 30)
    }

    /// True if this completed set exceeded its own ghost (last time's) weight or reps —
    /// the same lightweight PR heuristic used for the finish-workout celebration.
    var isPR: Bool {
        guard done, let w = weight, let r = reps else { return false }
        return w > ghostWeight || (w == ghostWeight && r > ghostReps)
    }
}
