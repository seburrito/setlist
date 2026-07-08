import Foundation

/// Pure functions over already-fetched `[Workout]` (views fetch once via @Query
/// and hand the array in) — streaks, PRs, muscle-group volume trends, and
/// per-exercise 1RM estimates, all derived from real stored sets. Nothing here
/// is mocked; it's the same "history queries are just the most recent workout
/// containing this exercise" principle the data model is built around.
enum Analytics {
    static func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(format: "%.1f", w)
    }

    static func formatVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : String(Int(v))
    }

    static func formatElapsed(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    struct SessionEntry: Identifiable {
        var id: Date { date }
        let date: Date
        let dateLabel: String
        let line: String
    }

    /// Past finished sessions that logged this exercise, most recent first —
    /// the "History" disclosure in focus mode and the library detail sheet.
    static func sessionHistory(_ workouts: [Workout], for exercise: Exercise, excluding: Workout? = nil) -> [SessionEntry] {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        var result: [SessionEntry] = []
        for w in workouts where w.isFinished && w !== excluding {
            guard let we = w.workoutExercises.first(where: { $0.exercise === exercise }) else { continue }
            let done = we.sortedSets.filter(\.done)
            guard !done.isEmpty else { continue }
            let line = done.map { "\(formatWeight($0.weight ?? 0))×\($0.reps ?? 0)" }.joined(separator: " · ")
            result.append(SessionEntry(date: w.startedAt, dateLabel: f.string(from: w.startedAt), line: line))
        }
        return result
    }

    // MARK: - Home

    struct SevenDayStats {
        let workouts: Int
        let sets: Int
        let volume: Double
    }

    static func last7DaysStats(_ workouts: [Workout], now: Date = .now) -> SevenDayStats {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        let recent = workouts.filter { $0.isFinished && $0.startedAt >= start }
        return SevenDayStats(
            workouts: recent.count,
            sets: recent.reduce(0) { $0 + $1.totalSetsDone },
            volume: recent.reduce(0) { $0 + $1.totalVolume }
        )
    }

    /// 7 booleans, oldest first, today last — whether a workout was logged that day.
    static func weekDots(_ workouts: [Workout], now: Date = .now) -> [Bool] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let finishedDays = Set(workouts.filter(\.isFinished).map { cal.startOfDay(for: $0.startedAt) })
        return (0..<7).map { i -> Bool in
            guard let day = cal.date(byAdding: .day, value: i - 6, to: today) else { return false }
            return finishedDays.contains(day)
        }
    }

    private static func weekStarts(_ workouts: [Workout]) -> Set<Date> {
        let cal = Calendar.current
        return Set(workouts.filter(\.isFinished).compactMap { cal.dateInterval(of: .weekOfYear, for: $0.startedAt)?.start })
    }

    static func currentStreakWeeks(_ workouts: [Workout], now: Date = .now) -> Int {
        let cal = Calendar.current
        let starts = weekStarts(workouts)
        guard !starts.isEmpty, var cursor = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        if !starts.contains(cursor) {
            cursor = cal.date(byAdding: .weekOfYear, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while starts.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func bestStreakWeeks(_ workouts: [Workout]) -> Int {
        let cal = Calendar.current
        let sorted = weekStarts(workouts).sorted()
        guard !sorted.isEmpty else { return 0 }
        var best = 0, current = 0
        var previous: Date?
        for start in sorted {
            if let p = previous, let expected = cal.date(byAdding: .weekOfYear, value: 1, to: p), expected == start {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = start
        }
        return best
    }

    // MARK: - Personal records

    struct PRResult: Identifiable {
        var id: String { exerciseName + String(date.timeIntervalSince1970) }
        let exerciseName: String
        let detail: String
        let date: Date
    }

    static func recentPRs(_ workouts: [Workout], limit: Int = 3) -> [PRResult] {
        struct Logged { let date: Date; let weight: Double; let reps: Int }
        var byExercise: [String: [Logged]] = [:]
        for w in workouts where w.isFinished {
            for we in w.workoutExercises {
                guard let name = we.exercise?.name else { continue }
                for s in we.sets where s.done {
                    guard let weight = s.weight, let reps = s.reps else { continue }
                    byExercise[name, default: []].append(Logged(date: w.startedAt, weight: weight, reps: reps))
                }
            }
        }

        func e1rm(_ l: Logged) -> Double { l.reps <= 1 ? l.weight : l.weight * (1 + Double(l.reps) / 30) }

        var events: [(name: String, date: Date, weight: Double, reps: Int)] = []
        for (name, entries) in byExercise {
            let sorted = entries.sorted { $0.date < $1.date }
            var best = -Double.infinity
            for entry in sorted {
                let rm = e1rm(entry)
                if rm > best, best > -Double.infinity {
                    events.append((name, entry.date, entry.weight, entry.reps))
                }
                best = max(best, rm)
            }
        }

        return events
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { PRResult(exerciseName: $0.name, detail: "\(formatWeight($0.weight)) kg × \($0.reps)", date: $0.date) }
    }

    // MARK: - Progress · by muscle group

    struct MuscleVolume: Identifiable {
        var id: String { name }
        let name: String
        /// Oldest → newest, one entry per week in the selected window.
        let weeklySeries: [Double]
        let total: Double
        let deltaPct: Double?
    }

    static func muscleGroupVolumes(_ workouts: [Workout], weeks: Int, now: Date = .now) -> [MuscleVolume] {
        let cal = Calendar.current
        guard let windowStart = cal.date(byAdding: .weekOfYear, value: -weeks, to: now),
              let priorStart = cal.date(byAdding: .weekOfYear, value: -weeks, to: windowStart) else { return [] }

        struct SetHit { let tags: [String]; let date: Date; let volume: Double }
        var hits: [SetHit] = []
        for w in workouts where w.isFinished {
            for we in w.workoutExercises {
                guard let tags = we.exercise?.muscleGroups, !tags.isEmpty else { continue }
                for s in we.sets where s.done {
                    guard let weight = s.weight, let reps = s.reps else { continue }
                    hits.append(SetHit(tags: tags, date: w.startedAt, volume: weight * Double(reps)))
                }
            }
        }

        let allTags = Set(hits.flatMap(\.tags))
        var results: [MuscleVolume] = []
        for tag in allTags {
            let tagHits = hits.filter { $0.tags.contains(tag) }
            let currentTotal = tagHits.filter { $0.date >= windowStart && $0.date <= now }.reduce(0) { $0 + $1.volume }
            let priorTotal = tagHits.filter { $0.date >= priorStart && $0.date < windowStart }.reduce(0) { $0 + $1.volume }
            guard currentTotal > 0 || priorTotal > 0 else { continue }

            var series: [Double] = []
            for k in 0..<weeks {
                guard let weekStart = cal.date(byAdding: .weekOfYear, value: k - weeks, to: now),
                      let weekEnd = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { series.append(0); continue }
                series.append(tagHits.filter { $0.date >= weekStart && $0.date < weekEnd }.reduce(0) { $0 + $1.volume })
            }

            let delta: Double? = priorTotal > 0 ? ((currentTotal - priorTotal) / priorTotal) * 100 : (currentTotal > 0 ? 100 : nil)
            results.append(MuscleVolume(name: tag, weeklySeries: series, total: currentTotal, deltaPct: delta))
        }
        return results.sorted { $0.total > $1.total }
    }

    /// A one-line imbalance callout, e.g. "Pull volume is 23% below push over the last 30 days."
    static func pushPullInsight(_ workouts: [Workout], now: Date = .now) -> String? {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -30, to: now) else { return nil }
        func volume(for tags: Set<String>) -> Double {
            var total = 0.0
            for w in workouts where w.isFinished && w.startedAt >= start {
                for we in w.workoutExercises {
                    guard let exTags = we.exercise?.muscleGroups, !tags.isDisjoint(with: exTags) else { continue }
                    for s in we.sets where s.done {
                        total += (s.weight ?? 0) * Double(s.reps ?? 0)
                    }
                }
            }
            return total
        }
        let push = volume(for: ["Chest", "Shoulders", "Triceps"])
        let pull = volume(for: ["Back", "Biceps", "Rear Delts"])
        guard push > 0, pull > 0 else { return nil }
        let diffPct = abs(push - pull) / max(push, pull) * 100
        guard diffPct >= 10 else { return nil }
        let lagging = push > pull ? "Pull" : "Push"
        let leading = push > pull ? "push" : "pull"
        return "\(lagging) volume is \(Int(diffPct.rounded()))% below \(leading) over the last 30 days."
    }

    // MARK: - Progress · by exercise

    struct ExerciseStat: Identifiable {
        var id: String { name }
        let name: String
        let subtitle: String
        let e1rm: Double
        let trendUp: Bool
    }

    static func exerciseStats(_ workouts: [Workout]) -> [ExerciseStat] {
        struct Logged { let date: Date; let weight: Double; let reps: Int }
        var byExercise: [String: [Logged]] = [:]
        for w in workouts where w.isFinished {
            for we in w.workoutExercises {
                guard let name = we.exercise?.name else { continue }
                for s in we.sets where s.done {
                    guard let weight = s.weight, let reps = s.reps else { continue }
                    byExercise[name, default: []].append(Logged(date: w.startedAt, weight: weight, reps: reps))
                }
            }
        }

        func e1rm(_ l: Logged) -> Double { l.reps <= 1 ? l.weight : l.weight * (1 + Double(l.reps) / 30) }

        var stats: [ExerciseStat] = []
        for (name, entries) in byExercise {
            let sorted = entries.sorted { $0.date < $1.date }
            guard let latest = sorted.last, let best = sorted.max(by: { e1rm($0) < e1rm($1) }) else { continue }
            let latestE1RM = e1rm(latest)
            let priorBest = sorted.dropLast().map(e1rm).max() ?? 0
            let sessionCount = Set(sorted.map { Calendar.current.startOfDay(for: $0.date) }).count
            stats.append(ExerciseStat(
                name: name,
                subtitle: "Best \(formatWeight(best.weight)) kg × \(best.reps) · \(sessionCount) session\(sessionCount == 1 ? "" : "s")",
                e1rm: latestE1RM,
                trendUp: latestE1RM >= priorBest
            ))
        }
        return stats.sorted { $0.e1rm > $1.e1rm }
    }

    // MARK: - History calendar

    /// Dominant split for everything logged on a given calendar day (nil if nothing was logged).
    static func splitKind(_ workouts: [Workout], on day: Date) -> SplitKind? {
        let cal = Calendar.current
        let dayWorkouts = workouts.filter { $0.isFinished && cal.isDate($0.startedAt, inSameDayAs: day) }
        guard !dayWorkouts.isEmpty else { return nil }
        let counts = Dictionary(grouping: dayWorkouts, by: { $0.splitKind })
        return counts.max { $0.value.count < $1.value.count }?.key
    }
}
