import SwiftUI
import SwiftData

private enum LibrarySegment: String, CaseIterable { case exercises = "Exercises", routines = "Routines" }

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.createdAt, order: .reverse) private var exercises: [Exercise]
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]

    @State private var segment: LibrarySegment = .exercises

    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    @State private var newExerciseTags = ""

    @State private var showAddRoutine = false
    @State private var newRoutineName = ""

    @State private var expandedRoutine: Routine?
    @State private var selectedExercise: Exercise?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Library").font(.numeral(32)).textCase(.uppercase)

                PillSegmented(options: LibrarySegment.allCases.map { ($0, $0.rawValue) }, selection: $segment)

                switch segment {
                case .exercises: exercisesSection
                case .routines: routinesSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 160)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailSheet(exercise: exercise)
        }
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        VStack(spacing: 12) {
            if showAddExercise {
                VStack(spacing: 10) {
                    TextField("Exercise name", text: $newExerciseName)
                        .textFieldStyle(SetlistFieldStyle())
                    TextField("Muscles · Equipment (e.g. Chest · Cable)", text: $newExerciseTags)
                        .textFieldStyle(SetlistFieldStyle())
                    HStack(spacing: 10) {
                        Button("Cancel") {
                            showAddExercise = false
                            newExerciseName = ""
                            newExerciseTags = ""
                        }
                        .buttonStyle(SetlistSecondaryButtonStyle())
                        Button("Add", action: addExercise)
                            .buttonStyle(SetlistPrimaryButtonStyle())
                    }
                }
                .setlistCard(padding: 14)
            } else {
                DashedAddButton(title: "New exercise") { showAddExercise = true }
            }

            VStack(spacing: 0) {
                ForEach(Array(exercises.enumerated()), id: \.element.persistentModelID) { index, exercise in
                    Button { selectedExercise = exercise } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name).font(.system(size: 16, weight: .semibold))
                                Text(exercise.tagLine).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text(lastUsed(exercise)).font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textTertiary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textPrimary)
                    .overlay(alignment: .bottom) {
                        if index < exercises.count - 1 { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
                    }
                }
            }
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
        }
    }

    private func addExercise() {
        let name = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let parts = newExerciseTags
            .split(separator: "·")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let equipment = parts.last ?? ""
        let muscles = parts.count > 1 ? Array(parts.dropLast()) : []
        let exercise = Exercise(name: name, muscleGroups: muscles, equipment: parts.count > 1 ? equipment : "")
        modelContext.insert(exercise)
        showAddExercise = false
        newExerciseName = ""
        newExerciseTags = ""
    }

    private func lastUsed(_ exercise: Exercise) -> String {
        for w in workouts where w.isFinished {
            if w.workoutExercises.contains(where: { $0.exercise === exercise }) {
                let f = DateFormatter()
                f.dateFormat = "MMM d"
                return f.string(from: w.startedAt)
            }
        }
        return "—"
    }

    // MARK: - Routines

    private var routinesSection: some View {
        VStack(spacing: 12) {
            if showAddRoutine {
                VStack(spacing: 10) {
                    TextField("Routine name (e.g. Upper Body B)", text: $newRoutineName)
                        .textFieldStyle(SetlistFieldStyle())
                    HStack(spacing: 10) {
                        Button("Cancel") {
                            showAddRoutine = false
                            newRoutineName = ""
                        }
                        .buttonStyle(SetlistSecondaryButtonStyle())
                        Button("Add", action: addRoutine)
                            .buttonStyle(SetlistPrimaryButtonStyle())
                    }
                }
                .setlistCard(padding: 14)
            } else {
                DashedAddButton(title: "New routine") { showAddRoutine = true }
            }

            VStack(spacing: 12) {
                ForEach(routines, id: \.persistentModelID) { routine in
                    VStack(spacing: 0) {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                expandedRoutine = expandedRoutine === routine ? nil : routine
                            }
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.name).font(.system(size: 16, weight: .semibold))
                                    let count = routine.entries.count
                                    Text("\(count) exercise\(count == 1 ? "" : "s")")
                                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                                    .rotationEffect(.degrees(expandedRoutine === routine ? 90 : 0))
                            }
                            .padding(.vertical, 13)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.textPrimary)

                        if expandedRoutine === routine {
                            VStack(spacing: 0) {
                                ForEach(routine.sortedEntries, id: \.persistentModelID) { entry in
                                    HStack {
                                        Text(entry.exercise?.name ?? "—")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.textPrimary.opacity(0.75))
                                        Spacer()
                                    }
                                    .padding(.vertical, 9)
                                    .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        }
                    }
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
                }
            }
        }
    }

    private func addRoutine() {
        let name = newRoutineName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        modelContext.insert(Routine(name: name))
        showAddRoutine = false
        newRoutineName = ""
    }
}

struct SetlistFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SetlistPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SetlistSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
