import SwiftUI
import SwiftData

private enum ProgressLens: String, CaseIterable { case muscle = "By muscle group", exercise = "By exercise" }

struct ProgressTabView: View {
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]

    @State private var lens: ProgressLens = .muscle
    @State private var weeks: Int = 8

    private var muscleVolumes: [Analytics.MuscleVolume] { Analytics.muscleGroupVolumes(workouts, weeks: weeks) }
    private var exerciseStats: [Analytics.ExerciseStat] { Analytics.exerciseStats(workouts) }
    private var insight: String? { Analytics.pushPullInsight(workouts) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Progress").font(.numeral(32)).textCase(.uppercase)

                PillSegmented(options: ProgressLens.allCases.map { ($0, $0.rawValue) }, selection: $lens)

                switch lens {
                case .muscle: muscleSection
                case .exercise: exerciseSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 160)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var muscleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Volume per muscle group").font(.system(size: 15, weight: .bold))
                Text("Weekly volume trend · change vs previous period")
                    .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.bottom, 12)

            PillSegmented(
                options: [(4, "4 weeks"), (8, "8 weeks"), (12, "12 weeks")],
                selection: $weeks,
                background: Theme.cardInset,
                font: .system(size: 12, weight: .semibold)
            )
            .padding(.bottom, 18)

            if muscleVolumes.isEmpty {
                Text("Log a few workouts to see volume trends per muscle group here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 8)
            } else {
                ForEach(muscleVolumes) { row in
                    HStack(spacing: 10) {
                        Text(row.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary.opacity(0.75))
                            .frame(width: 88, alignment: .leading)
                        Sparkline(values: row.weeklySeries)
                            .frame(height: 28)
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text(Analytics.formatVolume(row.total)).font(.numeral(18))
                            deltaLabel(row.deltaPct)
                        }
                        .frame(width: 96, alignment: .trailing)
                    }
                    .padding(.bottom, 14)
                }
            }
        }
        .setlistCard(padding: 16)
        .padding(.bottom, 14)

        if let insight {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
                Text(insight)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary.opacity(0.6))
            }
            .setlistCard(padding: 14)
        }
    }

    private func deltaLabel(_ pct: Double?) -> some View {
        Group {
            if let pct {
                Text((pct > 0 ? "+" : "") + String(Int(pct.rounded())) + "%")
                    .foregroundStyle(pct > 0 ? Theme.accent : (pct < 0 ? Theme.negative : Theme.textSecondary))
            } else {
                Text("—").foregroundStyle(Theme.textSecondary)
            }
        }
        .font(.system(size: 12, weight: .bold))
    }

    private var exerciseSection: some View {
        VStack(spacing: 0) {
            if exerciseStats.isEmpty {
                Text("Log a few workouts to see 1RM trends per exercise here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(exerciseStats.enumerated()), id: \.element.id) { index, stat in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.name).font(.system(size: 16, weight: .semibold))
                            Text(stat.subtitle).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("\(Int(stat.e1rm.rounded())) kg")
                            .font(.numeral(20))
                            .foregroundStyle(stat.trendUp ? Theme.accent : Theme.textPrimary)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .overlay(alignment: .bottom) {
                        if index < exerciseStats.count - 1 { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
                    }
                }
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }
}
