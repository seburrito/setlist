import Foundation
import SwiftData

/// Predefined muscle-group tags. Users can also add free-text custom tags,
/// so exercises store raw strings rather than this enum — this just gives
/// the picker UI a canonical starter list.
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"
    case glutes = "Glutes"
    case calves = "Calves"
    case rearDelts = "Rear Delts"

    var id: String { rawValue }
}

@Model
final class Exercise {
    var name: String
    /// Free-form tags: predefined muscle groups plus any custom ones the user typed.
    var muscleGroups: [String]
    /// e.g. "Barbell", "Cable", "Dumbbell", "Machine" — how the exercise is loaded.
    var equipment: String
    var notes: String
    /// The last machine/brand note the user typed for this exercise (e.g. "Hammer Strength").
    /// Ghosted into new workout sessions the same way weight/reps are.
    var lastMachineNote: String
    /// Archiving (instead of deleting) keeps history queries ("last time you did this") intact.
    var archived: Bool
    var createdAt: Date

    init(
        name: String,
        muscleGroups: [String] = [],
        equipment: String = "",
        notes: String = "",
        lastMachineNote: String = "",
        archived: Bool = false,
        createdAt: Date = .now
    ) {
        self.name = name
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.notes = notes
        self.lastMachineNote = lastMachineNote
        self.archived = archived
        self.createdAt = createdAt
    }

    /// "Chest · Triceps · Barbell" style subtitle used throughout the library list.
    var tagLine: String {
        var parts = muscleGroups
        if !equipment.isEmpty { parts.append(equipment) }
        return parts.joined(separator: " · ")
    }
}
