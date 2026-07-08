import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    let session: WorkoutSession
    let exercise: WorkoutExercise
    let index: Int

    private var isCurrent: Bool { !session.isEditing && session.currentIndex == index }
    private var isAllDone: Bool { exercise.isAllDone }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button { session.openFocus(index) } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(exercise.exercise?.name ?? "—").font(.system(size: 16, weight: .bold))
                        Text(exercise.tagLine).font(.system(size: 12)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textPrimary)

                if session.isEditing {
                    reorderControls
                } else {
                    trailingStatus
                }
            }
            .padding(.horizontal, 4)

            if !session.isEditing && !isAllDone {
                setsTable
            }
        }
        .padding(14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .strokeBorder(isCurrent ? Theme.accent : .clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
        .padding(.bottom, 12)
    }

    private var reorderControls: some View {
        HStack(spacing: 8) {
            chevronButton("chevron.up", enabled: index > 0) { session.moveExercise(index, direction: -1) }
            chevronButton("chevron.down", enabled: index < session.exercises.count - 1) { session.moveExercise(index, direction: 1) }
            Button { session.removeExercise(index) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xFF6B6B))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: 0xFF5A5A, opacity: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func chevronButton(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? Color.white.opacity(0.7) : Color.white.opacity(0.18))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    @ViewBuilder
    private var trailingStatus: some View {
        HStack(spacing: 10) {
            if isAllDone {
                CheckBadge(done: true, size: 26)
            } else if isCurrent {
                StatusChip(text: "NOW", filled: true, outlined: false)
            } else {
                Text("\(exercise.doneCount) of \(exercise.sets.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            Button { session.openFocus(index) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private var setsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SET").frame(width: 26, alignment: .leading)
                Text("PREVIOUS").frame(maxWidth: .infinity, alignment: .leading)
                Text("KG").frame(width: 60, alignment: .center)
                Text("REPS").frame(width: 48, alignment: .center)
                Text("✓").frame(width: 44, alignment: .center)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Theme.textTertiary.opacity(0.85))
            .padding(.top, 12)
            .padding(.horizontal, 4)

            ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.persistentModelID) { setIndex, set in
                SetRowView(session: session, exerciseIndex: index, setIndex: setIndex, workoutSet: set)
            }
        }
    }
}

struct SetRowView: View {
    let session: WorkoutSession
    let exerciseIndex: Int
    let setIndex: Int
    let workoutSet: WorkoutSet

    private var filled: Bool { workoutSet.weight != nil || workoutSet.done }

    var body: some View {
        HStack(spacing: 8) {
            Text("\(setIndex + 1)")
                .font(.numeral(16, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.35))
                .frame(width: 26, alignment: .leading)

            Text("\(Analytics.formatWeight(workoutSet.ghostWeight)) kg × \(workoutSet.ghostReps)")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { session.fillGhost(exerciseIndex: exerciseIndex, setIndex: setIndex) }

            valueText(Analytics.formatWeight(workoutSet.displayWeight))
                .frame(width: 60)
                .contentShape(Rectangle())
                .onTapGesture { session.fillGhost(exerciseIndex: exerciseIndex, setIndex: setIndex) }
            valueText(String(workoutSet.displayReps))
                .frame(width: 48)
                .contentShape(Rectangle())
                .onTapGesture { session.fillGhost(exerciseIndex: exerciseIndex, setIndex: setIndex) }

            Button {
                session.toggleSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
            } label: {
                CheckBadge(done: workoutSet.done)
            }
            .buttonStyle(.plain)
            .frame(width: 44)
        }
        .frame(height: 46)
        .padding(.horizontal, 4)
        .background(workoutSet.done ? Theme.accent.opacity(0.07) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func valueText(_ text: String) -> some View {
        Text(text)
            .font(.numeral(20))
            .foregroundStyle(workoutSet.done ? Theme.accent : (filled ? Color.white : Color.white.opacity(0.3)))
            .multilineTextAlignment(.center)
    }
}
