import SwiftUI
import SwiftData

@main
struct SetlistApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Exercise.self, Routine.self, RoutineEntry.self, Workout.self, WorkoutExercise.self, WorkoutSet.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        SeedData.populateIfNeeded(context: container.mainContext)
        try? container.mainContext.save()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(SettingsStore.shared.accent.color)
        }
        .modelContainer(container)
    }
}
