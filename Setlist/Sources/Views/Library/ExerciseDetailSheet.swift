import SwiftUI
import SwiftData

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]

    private var sessions: [Analytics.SessionEntry] {
        Analytics.sessionHistory(workouts, for: exercise)
    }

    private var bestSetLabel: String {
        let allDone = workouts.filter(\.isFinished)
            .flatMap { $0.workoutExercises }
            .filter { $0.exercise === exercise }
            .flatMap(\.sets)
            .filter(\.done)
        guard let best = allDone.max(by: { $0.estimated1RM < $1.estimated1RM }), let w = best.weight, let r = best.reps else { return "—" }
        return "\(Analytics.formatWeight(w)) kg × \(r)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(exercise.name).font(.numeral(26)).textCase(.uppercase)
                Spacer()
            }
            Text(exercise.tagLine).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)

            HStack(spacing: 10) {
                statTile("BEST SET", bestSetLabel)
                statTile("LAST USED", sessions.first?.dateLabel ?? "—")
            }

            if sessions.isEmpty {
                Text("Session history appears here after your first workout with this exercise.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardInset)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RECENT SESSIONS").font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(Theme.textTertiary)
                    ForEach(Array(sessions.prefix(6).enumerated()), id: \.element.id) { index, session in
                        HStack(spacing: 12) {
                            Text(session.dateLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 52, alignment: .leading)
                            Text(session.line)
                                .font(.numeral(15, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary.opacity(0.8))
                        }
                        .padding(.vertical, 8)
                        .overlay(alignment: .top) {
                            if index > 0 { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardInset)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .background(Theme.card.ignoresSafeArea())
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(Theme.textTertiary)
            Text(value).font(.numeral(22))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardInset)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
