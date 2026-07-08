import SwiftUI
import SwiftData

/// The full-screen "now playing" surface for the active workout. Per the final
/// design direction this is an *editing/overview* screen — reorder, add, remove,
/// see status at a glance — while actually logging sets happens in Focus mode.
/// Pause is a non-blocking toggle; nothing here stops you from tapping any tab
/// underneath and navigating freely.
struct ActiveWorkoutOverview: View {
    let session: WorkoutSession
    @Query(sort: \Exercise.name) private var libraryExercises: [Exercise]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("\(session.exercises.count) exercises")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(1)
                                .foregroundStyle(Theme.textSecondary)
                                .textCase(.uppercase)
                            Spacer()
                            Button(session.isEditing ? "Done" : "Edit") { session.toggleEditing() }
                                .buttonStyle(EditPillButtonStyle(active: session.isEditing))
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 10)

                        ForEach(Array(session.exercises.enumerated()), id: \.element.persistentModelID) { index, we in
                            ExerciseCardView(session: session, exercise: we, index: index)
                        }

                        if session.showAdd {
                            addExercisePanel
                        } else {
                            DashedAddButton(title: "Add exercise", height: 50) { session.showAdd = true }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 140)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)

            if session.isRestBarVisible && session.focusIndex == nil {
                RestTimerBar(session: session)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
            }
        }
        .overlay {
            if let index = session.focusIndex {
                FocusModeView(session: session, index: index)
            }
        }
        .overlay {
            if session.showFinishConfirm {
                FinishConfirmSheet(session: session)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            IconButton(systemName: "chevron.down") { session.collapse() }
            VStack(spacing: 1) {
                Text(session.activeWorkout?.name ?? "")
                    .font(.numeral(20))
                    .textCase(.uppercase)
                    .lineLimit(1)
                Text(elapsedLine)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(session.isPaused ? Theme.accent : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            Button(session.isPaused ? "Resume" : "Pause") { session.togglePause() }
                .buttonStyle(HeaderPillButtonStyle(background: Theme.card, foreground: .white.opacity(0.85)))
            Button("Finish") { session.requestFinish() }
                .buttonStyle(HeaderPillButtonStyle(background: Theme.accent.opacity(0.16), foreground: Theme.accent, bold: true))
        }
        .padding(.horizontal, 16)
        .padding(.top, 66)
        .padding(.bottom, 10)
    }

    private var elapsedLine: String {
        session.isPaused
            ? "Paused · \(Analytics.formatElapsed(session.elapsedSeconds))"
            : "\(Analytics.formatElapsed(session.elapsedSeconds)) elapsed"
    }

    private var addOptions: [Exercise] {
        let existing = Set(session.exercises.compactMap { $0.exercise?.persistentModelID })
        return Array(libraryExercises.filter { !existing.contains($0.persistentModelID) }.prefix(5))
    }

    private var addExercisePanel: some View {
        VStack(spacing: 4) {
            ForEach(addOptions, id: \.persistentModelID) { exercise in
                Button { session.addExercise(exercise) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accent)
                        Text(exercise.name).font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(exercise.tagLine).font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textPrimary)
            }
            if addOptions.isEmpty {
                Text("No more exercises in your library to add.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 10)
            }
            Button("Cancel") { session.showAdd = false }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.vertical, 10)
        }
        .padding(8)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
        .padding(.bottom, 12)
    }
}

struct HeaderPillButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color
    var bold: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: bold ? .bold : .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct EditPillButtonStyle: ButtonStyle {
    var active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(active ? Theme.onAccent : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(active ? Theme.accent : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
