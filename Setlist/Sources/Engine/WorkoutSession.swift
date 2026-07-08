import Foundation
import SwiftData
import Observation

/// Drives the single active workout, if any. This is the "heart of the app":
/// starting/finishing, the elapsed + rest timers, pause (a non-blocking toggle —
/// you can navigate anywhere while paused), edit-mode reorder/remove/add, and
/// set completion with ghost-value fill-in. One instance lives for the whole
/// app session (see SetlistApp) so the mini-bar / rest timer / focus mode all
/// share the same state no matter which tab is on screen.
@Observable
final class WorkoutSession {
    private let context: ModelContext

    private(set) var activeWorkout: Workout?
    var isExpanded = false
    var isPaused = false
    var focusIndex: Int?
    var isEditing = false
    var showAdd = false
    var showFinishConfirm = false
    var showHistoryDisclosure = false

    var elapsedSeconds = 0
    var restRemaining = 0
    var restTotal = 0

    private var timer: Timer?

    init(context: ModelContext) {
        self.context = context
    }

    deinit { timer?.invalidate() }

    // MARK: - Derived state

    var isSheetVisible: Bool { activeWorkout != nil && isExpanded }
    var isMiniBarVisible: Bool { activeWorkout != nil && focusIndex == nil }
    var isRestBarVisible: Bool { isResting && isSheetVisible }
    var isResting: Bool { restRemaining > 0 }
    var restProgress: Double { restTotal > 0 ? Double(restRemaining) / Double(restTotal) : 0 }

    var exercises: [WorkoutExercise] { activeWorkout?.sortedExercises ?? [] }

    var currentIndex: Int? {
        exercises.firstIndex { !$0.isAllDone }
    }

    var currentExercise: WorkoutExercise? {
        guard let i = currentIndex else { return nil }
        return exercises[i]
    }

    var focusedExercise: WorkoutExercise? {
        guard let i = focusIndex, exercises.indices.contains(i) else { return nil }
        return exercises[i]
    }

    // MARK: - Lifecycle

    func start(routine: Routine?) {
        let name = routine?.name ?? "Blank Workout"
        let workout = Workout(name: name, startedAt: .now, routine: routine)
        context.insert(workout)

        if let routine {
            for entry in routine.sortedEntries {
                guard let exercise = entry.exercise else { continue }
                let we = makeWorkoutExercise(for: exercise, position: entry.position, targetSets: entry.targetSets, targetReps: entry.targetReps)
                we.workout = workout
                workout.workoutExercises.append(we)
            }
        }

        // Workouts always start on the overview — focus mode is reached by
        // tapping a card or the mini-bar, never automatically.
        activeWorkout = workout
        isExpanded = true
        isPaused = false
        focusIndex = nil
        isEditing = false
        showAdd = false
        elapsedSeconds = 0
        restRemaining = 0
        restTotal = 0
        startTicking()
    }

    func expandToCurrent() {
        isExpanded = true
        focusIndex = currentIndex
        showHistoryDisclosure = false
    }

    func collapse() {
        isExpanded = false
        focusIndex = nil
    }

    func togglePause() { isPaused.toggle() }

    private func startTicking() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard activeWorkout != nil, !isPaused else { return }
        elapsedSeconds += 1
        if restRemaining > 0 { restRemaining -= 1 }
    }

    // MARK: - Edit mode

    func toggleEditing() { isEditing.toggle(); showAdd = false }

    func moveExercise(_ index: Int, direction: Int) {
        var list = exercises
        let j = index + direction
        guard list.indices.contains(index), list.indices.contains(j) else { return }
        list.swapAt(index, j)
        for (i, ex) in list.enumerated() { ex.position = i }
    }

    func removeExercise(_ index: Int) {
        guard let workout = activeWorkout, exercises.indices.contains(index) else { return }
        let toRemove = exercises[index]
        workout.workoutExercises.removeAll { $0 === toRemove }
        context.delete(toRemove)
        if focusIndex == index { focusIndex = nil }
    }

    func addExercise(_ exercise: Exercise) {
        guard let workout = activeWorkout else { return }
        let position = (workout.workoutExercises.map(\.position).max() ?? -1) + 1
        let we = makeWorkoutExercise(for: exercise, position: position, targetSets: 3, targetReps: 10)
        we.workout = workout
        workout.workoutExercises.append(we)
        showAdd = false
    }

    private func makeWorkoutExercise(for exercise: Exercise, position: Int, targetSets: Int, targetReps: Int) -> WorkoutExercise {
        let last = try? lastWorkoutExercise(for: exercise)
        let machine = (last?.machineNote.isEmpty == false) ? (last?.machineNote ?? "") : exercise.lastMachineNote
        let we = WorkoutExercise(position: position, exercise: exercise, machineNote: machine)
        context.insert(we)

        let lastSets = last?.sortedSets ?? []
        for i in 0..<max(targetSets, 1) {
            let ghost: (Double, Int)
            if i < lastSets.count {
                let s = lastSets[i]
                ghost = (s.weight ?? s.ghostWeight, s.reps ?? s.ghostReps)
            } else {
                ghost = (20, targetReps)
            }
            let set = WorkoutSet(position: i, ghostWeight: ghost.0, ghostReps: ghost.1)
            context.insert(set)
            we.sets.append(set)
        }
        return we
    }

    private func lastWorkoutExercise(for exercise: Exercise) throws -> WorkoutExercise? {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt != nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 60
        let recent = try context.fetch(descriptor)
        for workout in recent where workout !== activeWorkout {
            if let match = workout.workoutExercises.first(where: { $0.exercise === exercise }) {
                return match
            }
        }
        return nil
    }

    // MARK: - Focus navigation

    func openFocus(_ index: Int) {
        focusIndex = index
        showHistoryDisclosure = false
    }

    func closeFocus() { focusIndex = nil }

    func focusPrev() {
        guard let i = focusIndex, i > 0 else { return }
        focusIndex = i - 1
        showHistoryDisclosure = false
    }

    func focusNext() {
        guard let i = focusIndex, i < exercises.count - 1 else { return }
        focusIndex = i + 1
        showHistoryDisclosure = false
    }

    func toggleHistoryDisclosure() { showHistoryDisclosure.toggle() }

    // MARK: - Sets

    private func set(_ exerciseIndex: Int, _ setIndex: Int) -> WorkoutSet? {
        guard exercises.indices.contains(exerciseIndex) else { return nil }
        let sets = exercises[exerciseIndex].sortedSets
        guard sets.indices.contains(setIndex) else { return nil }
        return sets[setIndex]
    }

    func fillGhost(exerciseIndex: Int, setIndex: Int) {
        guard let s = set(exerciseIndex, setIndex), !s.done, s.weight == nil else { return }
        s.weight = s.ghostWeight
        s.reps = s.ghostReps
    }

    func toggleSet(exerciseIndex: Int, setIndex: Int) {
        guard let s = set(exerciseIndex, setIndex) else { return }
        if s.done {
            s.done = false
        } else {
            if s.weight == nil { s.weight = s.ghostWeight; s.reps = s.ghostReps }
            s.done = true
            s.completedAt = .now
            if SettingsStore.shared.restTimerEnabled {
                restTotal = SettingsStore.shared.restDuration
                restRemaining = SettingsStore.shared.restDuration
            }
        }
    }

    func adjustSet(exerciseIndex: Int, setIndex: Int, deltaWeight: Double, deltaReps: Int) {
        guard let s = set(exerciseIndex, setIndex) else { return }
        if s.weight == nil { s.weight = s.ghostWeight; s.reps = s.ghostReps }
        s.weight = max(0, (((s.weight ?? 0) + deltaWeight) * 10).rounded() / 10)
        s.reps = max(0, (s.reps ?? 0) + deltaReps)
    }

    func setMachineNote(exerciseIndex: Int, text: String) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        let we = exercises[exerciseIndex]
        we.machineNote = text
        we.exercise?.lastMachineNote = text
    }

    // MARK: - Rest timer

    func adjustRest(_ delta: Int) {
        if delta > 0 {
            restRemaining += delta
            restTotal = max(restTotal, restRemaining)
        } else {
            restRemaining = max(0, restRemaining + delta)
        }
    }

    func skipRest() { restRemaining = 0 }

    // MARK: - Finish

    struct FinishSummary {
        let duration: String
        let setsDone: Int
        let volume: Double
        let prExerciseName: String?
    }

    var finishSummary: FinishSummary? {
        guard let workout = activeWorkout else { return nil }
        let doneSets = workout.completedSets
        let prExercise = exercises.first { $0.sets.contains { $0.isPR } }
        return FinishSummary(
            duration: Analytics.formatElapsed(elapsedSeconds),
            setsDone: doneSets.count,
            volume: doneSets.reduce(0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) },
            prExerciseName: prExercise?.exercise?.name
        )
    }

    func requestFinish() { showFinishConfirm = true }
    func cancelFinish() { showFinishConfirm = false }

    func confirmFinish() {
        guard let workout = activeWorkout else { return }
        workout.endedAt = .now
        try? context.save()
        reset()
    }

    private func reset() {
        timer?.invalidate()
        timer = nil
        activeWorkout = nil
        isExpanded = false
        isPaused = false
        focusIndex = nil
        isEditing = false
        showAdd = false
        showFinishConfirm = false
        showHistoryDisclosure = false
        elapsedSeconds = 0
        restRemaining = 0
        restTotal = 0
    }
}
