import SwiftUI

struct WorkoutDetailSheet: View {
    let workout: Workout

    private var dateMeta: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        let minutes = Int(workout.duration / 60)
        return "\(f.string(from: workout.startedAt)) · \(minutes) min · \(workout.totalSetsDone) sets"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(workout.name).font(.numeral(26)).textCase(.uppercase)
            Text(dateMeta).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)

            VStack(spacing: 0) {
                ForEach(Array(workout.sortedExercises.enumerated()), id: \.element.persistentModelID) { index, we in
                    HStack(spacing: 12) {
                        Text(we.exercise?.name ?? "—")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(setsLine(we))
                            .font(.numeral(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary.opacity(0.65))
                    }
                    .padding(.vertical, 11)
                    .overlay(alignment: .top) {
                        if index > 0 { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(Theme.cardInset)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .background(Theme.card.ignoresSafeArea())
    }

    private func setsLine(_ we: WorkoutExercise) -> String {
        we.sortedSets.filter(\.done)
            .map { "\(Analytics.formatWeight($0.weight ?? 0))×\($0.reps ?? 0)" }
            .joined(separator: " · ")
    }
}
