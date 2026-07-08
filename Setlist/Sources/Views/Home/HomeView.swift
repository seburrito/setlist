import SwiftUI
import SwiftData

struct HomeView: View {
    let session: WorkoutSession
    @Binding var showStartPicker: Bool
    @Binding var showSettings: Bool

    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]

    private var stats: Analytics.SevenDayStats { Analytics.last7DaysStats(workouts) }
    private var currentStreak: Int { Analytics.currentStreakWeeks(workouts) }
    private var bestStreak: Int { Analytics.bestStreakWeeks(workouts) }
    private var weekDots: [Bool] { Analytics.weekDots(workouts) }
    private var prs: [Analytics.PRResult] { Analytics.recentPRs(workouts, limit: 3) }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: .now).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    SetlistMark(size: 22)
                    Text("Setlist")
                        .font(.numeral(32))
                        .textCase(.uppercase)
                    Spacer()
                    IconButton(systemName: "gearshape.fill") { showSettings = true }
                }
                Text(dateLine)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, -6)

                Button {
                    if session.activeWorkout != nil {
                        session.expandToCurrent()
                    } else {
                        showStartPicker = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 14))
                        Text(session.activeWorkout != nil ? "Resume workout" : "Start workout")
                            .font(.numeral(20))
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
                }
                .buttonStyle(.plain)

                sevenDayCard
                streakCard
                if !prs.isEmpty { prCard }
            }
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 160)
        }
        .scrollIndicators(.hidden)
    }

    private var sevenDayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last 7 days")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                statColumn(String(stats.workouts), "Workouts")
                statColumn(String(stats.sets), "Sets")
                statColumn(Analytics.formatVolume(stats.volume), "kg volume")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .setlistCard()
    }

    private func statColumn(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.numeral(34))
            Text(label.uppercased())
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            Text(String(currentStreak))
                .font(.numeral(52))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("week streak").font(.system(size: 15, weight: .semibold))
                Text("Best: \(bestStreak) weeks")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(Array(weekDots.enumerated()), id: \.offset) { _, on in
                    Circle()
                        .fill(on ? Theme.accent : Color.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .setlistCard()
    }

    private var prCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent PRs")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 6)
            ForEach(Array(prs.enumerated()), id: \.element.id) { index, pr in
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                    Text(pr.exerciseName)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(pr.detail).font(.numeral(18, weight: .bold))
                    Text(shortDate(pr.date))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 42, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    if index < prs.count - 1 {
                        Rectangle().fill(Theme.hairline).frame(height: 0.5)
                    }
                }
            }
        }
        .setlistCard()
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
