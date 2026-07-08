import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedWorkout: Workout?

    private var calendar: Calendar { .current }

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private var canGoPrev: Bool {
        workouts.contains { $0.isFinished && $0.startedAt < displayedMonth }
    }

    private var canGoNext: Bool {
        displayedMonth < calendar.startOfMonth(for: .now)
    }

    private struct Day: Identifiable {
        let id: Int
        let number: Int?
        let date: Date?
        let split: SplitKind?
        let isToday: Bool
    }

    private var days: [Day] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let weekday = calendar.component(.weekday, from: displayedMonth)
        let leadingBlanks = (weekday + 5) % 7 // Monday-first offset
        var result: [Day] = (0..<leadingBlanks).map { Day(id: -($0 + 1), number: nil, date: nil, split: nil, isToday: false) }
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: displayedMonth) else { continue }
            result.append(Day(
                id: day,
                number: day,
                date: date,
                split: Analytics.splitKind(workouts, on: date),
                isToday: calendar.isDateInToday(date)
            ))
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("History").font(.numeral(32)).textCase(.uppercase)

                calendarCard

                VStack(spacing: 0) {
                    ForEach(Array(workouts.filter(\.isFinished).enumerated()), id: \.element.persistentModelID) { index, workout in
                        Button { selectedWorkout = workout } label: {
                            HStack(spacing: 12) {
                                SplitDot(color: workout.splitKind.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(workout.name).font(.system(size: 16, weight: .semibold))
                                    Text(meta(for: workout)).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Text(shortDate(workout.startedAt)).font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textTertiary)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.textPrimary)
                        .overlay(alignment: .bottom) {
                            if index < workouts.filter(\.isFinished).count - 1 { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
                        }
                    }
                }
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 160)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailSheet(workout: workout)
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 12) {
            HStack {
                IconButton(systemName: "chevron.left", background: .white.opacity(0.05),
                           foreground: canGoPrev ? .white.opacity(0.7) : .white.opacity(0.18), size: 34) {
                    if canGoPrev { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth }
                }
                Spacer()
                Text(monthLabel).font(.system(size: 16, weight: .bold))
                Spacer()
                IconButton(systemName: "chevron.right", background: .white.opacity(0.05),
                           foreground: canGoNext ? .white.opacity(0.7) : .white.opacity(0.18), size: 34) {
                    if canGoNext { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth }
                }
            }

            HStack(spacing: 0) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { d in
                    Text(d).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(days) { day in
                    VStack(spacing: 4) {
                        if let number = day.number, let date = day.date {
                            Text(String(number))
                                .font(.system(size: 15, weight: day.isToday ? .heavy : .semibold))
                                .foregroundStyle(day.isToday ? Theme.onAccent : (day.split != nil ? .white : Theme.textSecondary))
                                .frame(width: 30, height: 30)
                                .background(day.isToday ? Theme.accent : .clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    if day.split != nil { selectedWorkout = dayWorkout(date) }
                                }
                            Circle().fill(day.split?.color ?? .clear).frame(width: 5, height: 5)
                        } else {
                            Color.clear.frame(width: 30, height: 30)
                            Circle().fill(.clear).frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 42)
                }
            }

            HStack(spacing: 14) {
                legendItem("Push", Theme.accent)
                legendItem("Pull", Theme.splitPull)
                legendItem("Legs", Theme.splitLegs)
                Spacer()
            }
            .padding(.top, 4)
            .overlay(alignment: .top) { Rectangle().fill(Theme.hairlineStrong).frame(height: 0.5) }
        }
        .setlistCard()
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
    }

    private func dayWorkout(_ date: Date) -> Workout? {
        workouts.first { $0.isFinished && calendar.isDate($0.startedAt, inSameDayAs: date) }
    }

    private func meta(for workout: Workout) -> String {
        let minutes = Int(workout.duration / 60)
        return "\(minutes) min · \(workout.totalSetsDone) sets · \(groupedInt(workout.totalVolume)) kg"
    }

    private func groupedInt(_ v: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = ","
        return nf.string(from: NSNumber(value: Int(v))) ?? String(Int(v))
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
