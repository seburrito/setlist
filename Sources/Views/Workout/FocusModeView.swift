import SwiftUI
import SwiftData

/// "What am I doing right now" — the screen that actually drives the workout.
/// Big stepper for the current set, prev/next exercise navigation, and once
/// every set is done either advances to the next exercise or offers to finish.
struct FocusModeView: View {
    let session: WorkoutSession
    let index: Int

    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]

    private var exercise: WorkoutExercise? {
        session.exercises.indices.contains(index) ? session.exercises[index] : nil
    }
    private var sets: [WorkoutSet] { exercise?.sortedSets ?? [] }
    private var currentSetIndex: Int {
        let firstIncomplete = sets.firstIndex { !$0.done }
        return firstIncomplete ?? max(sets.count - 1, 0)
    }
    private var allDone: Bool { !sets.isEmpty && sets.allSatisfy(\.done) }
    private var isLast: Bool { index == session.exercises.count - 1 }
    private var statusText: String {
        allDone ? "DONE" : (index == session.currentIndex ? "CURRENT" : "UP NEXT")
    }

    private var machineBinding: Binding<String> {
        Binding(
            get: { exercise?.machineNote ?? "" },
            set: { session.setMachineNote(exerciseIndex: index, text: $0) }
        )
    }

    var body: some View {
        Group {
            if let exercise {
                content(for: exercise)
            } else {
                EmptyView()
            }
        }
    }

    private func content(for exercise: WorkoutExercise) -> some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    topBar

                    VStack(alignment: .leading, spacing: 5) {
                        Text(exercise.exercise?.name ?? "—")
                            .font(.numeral(30))
                            .textCase(.uppercase)
                        Text(exercise.tagLine)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    centerCard(exercise)
                    summaryCard(exercise)
                    machineCard
                    historyCard(exercise)
                    notesCard(exercise)
                }
                .padding(.horizontal, 16)
                .padding(.top, 66)
                .padding(.bottom, 150)
            }

            if session.isRestBarVisible {
                RestTimerBar(session: session)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .transition(.opacity)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button { session.closeFocus() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold))
                    Text("Overview").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            Spacer()
            StatusChip(text: statusText, filled: statusText == "CURRENT", outlined: statusText == "UP NEXT")
            Text("\(index + 1) / \(session.exercises.count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            navButton("chevron.left", enabled: index > 0) { session.focusPrev() }
            navButton("chevron.right", enabled: index < session.exercises.count - 1) { session.focusNext() }
        }
    }

    private func navButton(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? Color.white.opacity(0.75) : Color.white.opacity(0.18))
                .frame(width: 36, height: 36)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    @ViewBuilder
    private func centerCard(_ exercise: WorkoutExercise) -> some View {
        VStack(spacing: 16) {
            Text(allDone ? "ALL SETS DONE" : "SET \(currentSetIndex + 1) OF \(sets.count)")
                .font(.numeral(15))
                .tracking(2)
                .foregroundStyle(Theme.textSecondary)

            if allDone {
                VStack(spacing: 14) {
                    Circle().fill(Theme.accent).frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: "checkmark").font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.onAccent)
                        }
                    if isLast {
                        Button { session.requestFinish() } label: {
                            Text("Finish workout").font(.numeral(18)).textCase(.uppercase).foregroundStyle(Theme.onAccent)
                                .padding(.horizontal, 24).frame(height: 50).background(Theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }.buttonStyle(.plain)
                    } else {
                        Button { session.focusNext() } label: {
                            HStack(spacing: 8) {
                                Text("Next exercise").font(.numeral(18)).textCase(.uppercase)
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 24).frame(height: 50).background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } else {
                let set = sets[currentSetIndex]
                let filled = set.weight != nil
                HStack(alignment: .top, spacing: 6) {
                    stepperColumn(label: "KG", value: Analytics.formatWeight(set.displayWeight), filled: filled,
                                  minus: { session.adjustSet(exerciseIndex: index, setIndex: currentSetIndex, deltaWeight: -2.5, deltaReps: 0) },
                                  plus: { session.adjustSet(exerciseIndex: index, setIndex: currentSetIndex, deltaWeight: 2.5, deltaReps: 0) })
                    Text("×").font(.numeral(28, weight: .semibold)).foregroundStyle(Color.white.opacity(0.25)).padding(.top, 12)
                    stepperColumn(label: "REPS", value: String(set.displayReps), filled: filled,
                                  minus: { session.adjustSet(exerciseIndex: index, setIndex: currentSetIndex, deltaWeight: 0, deltaReps: -1) },
                                  plus: { session.adjustSet(exerciseIndex: index, setIndex: currentSetIndex, deltaWeight: 0, deltaReps: 1) })
                }

                Button {
                    session.toggleSet(exerciseIndex: index, setIndex: currentSetIndex)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .bold))
                        Text("Log set").font(.numeral(19)).textCase(.uppercase)
                    }
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Text("Last time: \(Analytics.formatWeight(set.ghostWeight)) kg × \(set.ghostReps)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }

    private func stepperColumn(label: String, value: String, filled: Bool, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Text(value).font(.numeral(56)).foregroundStyle(filled ? Color.white : Color.white.opacity(0.3))
            Text(label).font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(Theme.textTertiary)
            HStack(spacing: 8) {
                stepButton("minus", action: minus)
                stepButton("plus", action: plus)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func stepButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 38)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func summaryCard(_ exercise: WorkoutExercise) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sets.enumerated()), id: \.element.persistentModelID) { i, s in
                let isCur = i == currentSetIndex && !allDone
                HStack(spacing: 10) {
                    Text("Set \(i + 1)")
                        .font(.numeral(16, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .frame(width: 42, alignment: .leading)
                    Text("\(Analytics.formatWeight(s.displayWeight)) kg × \(s.displayReps)")
                        .font(.numeral(17, weight: .bold))
                        .foregroundStyle(s.done ? .white : (isCur ? Theme.accent : Color.white.opacity(0.3)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    CheckBadge(done: s.done, size: 24)
                }
                .padding(.vertical, 11)
                .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.hairline).frame(height: 0.5) } }
            }
        }
        .padding(.horizontal, 16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }

    private var machineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MACHINE").font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(Theme.textSecondary)
            TextField("e.g. Hammer Strength, Technogym…", text: machineBinding)
                .textFieldStyle(SetlistFieldStyle())
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }

    @ViewBuilder
    private func historyCard(_ exercise: WorkoutExercise) -> some View {
        let history = exercise.exercise.map { Analytics.sessionHistory(workouts, for: $0, excluding: session.activeWorkout) } ?? []
        VStack(alignment: .leading, spacing: 0) {
            Button {
                session.toggleHistoryDisclosure()
            } label: {
                HStack {
                    Text("History").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(session.showHistoryDisclosure ? "Hide" : "Last \(history.count) sessions")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textPrimary)

            if session.showHistoryDisclosure {
                VStack(spacing: 8) {
                    ForEach(Array(history.prefix(3).enumerated()), id: \.element.id) { i, h in
                        HStack(spacing: 12) {
                            Text(h.dateLabel).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textSecondary).frame(width: 52, alignment: .leading)
                            Text(h.line).font(.numeral(15, weight: .semibold)).foregroundStyle(Color.white.opacity(0.8))
                        }
                        .padding(.top, 8)
                        .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.hairline).frame(height: 0.5) } }
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }

    private func notesCard(_ exercise: WorkoutExercise) -> some View {
        let notes = exercise.exercise?.notes ?? ""
        return VStack(alignment: .leading, spacing: 6) {
            Text("NOTES").font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(Theme.textSecondary)
            Text(notes.isEmpty ? "No notes yet." : notes)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }
}
