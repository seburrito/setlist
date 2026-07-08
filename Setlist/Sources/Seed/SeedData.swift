import Foundation
import SwiftData

/// First-launch seeding: creates the exercise/routine catalog plus ~13 weeks of
/// real, internally-consistent workout history (alternating Push/Pull/Legs with
/// gradual progressive overload) so the app doesn't open to an empty Progress/
/// History tab. Everything after this is genuinely computed from what's stored —
/// there is no further mock data anywhere in the app.
enum SeedData {
    static func populateIfNeeded(context: ModelContext) {
        let alreadySeeded = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard alreadySeeded == 0 else { return }

        func makeExercise(_ name: String, _ muscles: [String], _ equipment: String, _ notes: String = "", machine: String = "") -> Exercise {
            let e = Exercise(name: name, muscleGroups: muscles, equipment: equipment, notes: notes, lastMachineNote: machine)
            context.insert(e)
            return e
        }

        let benchPress = makeExercise("Bench Press", ["Chest", "Triceps"], "Barbell",
            "Pinky on the ring. Feet planted, slight arch. Pause on chest for first set.")
        let inclineDB = makeExercise("Incline Dumbbell Press", ["Chest", "Shoulders"], "Dumbbell",
            "Bench at notch 3. Kick dumbbells up one at a time.")
        let ohp = makeExercise("Overhead Press", ["Shoulders", "Triceps"], "Barbell",
            "Squeeze glutes, ribs down. No leg drive.")
        let cableFly = makeExercise("Cable Fly", ["Chest"], "Cable",
            "Pulleys at chest height. Slow eccentric.", machine: "FreeMotion dual cable")
        let tricepsPushdown = makeExercise("Triceps Pushdown", ["Triceps"], "Cable",
            "Rope attachment, seat 4. Elbows pinned.")
        let barbellRow = makeExercise("Barbell Row", ["Back", "Biceps"], "Barbell")
        let latPulldown = makeExercise("Lat Pulldown", ["Back", "Biceps"], "Cable")
        let facePull = makeExercise("Face Pull", ["Rear Delts"], "Cable")
        let bicepsCurl = makeExercise("Biceps Curl", ["Biceps"], "Dumbbell")
        let squat = makeExercise("Squat", ["Quads", "Glutes"], "Barbell")
        let rdl = makeExercise("Romanian Deadlift", ["Hamstrings", "Glutes"], "Barbell")
        let legPress = makeExercise("Leg Press", ["Quads", "Glutes"], "Machine")
        let calfRaise = makeExercise("Calf Raise", ["Calves"], "Machine")

        func makeRoutine(_ name: String, _ items: [(Exercise, Int, Int)]) -> Routine {
            let r = Routine(name: name)
            context.insert(r)
            for (i, item) in items.enumerated() {
                let entry = RoutineEntry(position: i, targetSets: item.1, targetReps: item.2, exercise: item.0, routine: r)
                context.insert(entry)
                r.entries.append(entry)
            }
            return r
        }

        let pushDayA = makeRoutine("Push Day A", [
            (benchPress, 3, 8), (inclineDB, 3, 10), (ohp, 3, 6), (cableFly, 3, 12), (tricepsPushdown, 3, 12)
        ])
        let pullDayA = makeRoutine("Pull Day A", [
            (barbellRow, 3, 8), (latPulldown, 3, 10), (facePull, 2, 15), (bicepsCurl, 3, 12)
        ])
        let legDay = makeRoutine("Leg Day", [
            (squat, 3, 6), (rdl, 3, 8), (legPress, 2, 10), (calfRaise, 3, 15)
        ])

        generateHistory(context: context, plans: [
            (pushDayA, [(benchPress, 3, 8, 70.0), (inclineDB, 3, 10, 24.0), (ohp, 3, 6, 40.0),
                        (cableFly, 3, 12, 20.0), (tricepsPushdown, 3, 12, 30.0)]),
            (pullDayA, [(barbellRow, 3, 8, 75.0), (latPulldown, 3, 10, 60.0),
                        (facePull, 2, 15, 20.0), (bicepsCurl, 3, 12, 12.0)]),
            (legDay, [(squat, 3, 6, 100.0), (rdl, 3, 8, 90.0),
                      (legPress, 2, 10, 180.0), (calfRaise, 3, 15, 70.0)])
        ])
    }

    private static func generateHistory(
        context: ModelContext,
        plans: [(routine: Routine, exercises: [(Exercise, Int, Int, Double)])]
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let historyStart = calendar.date(byAdding: .day, value: -90, to: today) else { return }

        // Ghost values and progressive overload both come from what the previous
        // real session logged for that exercise — exactly the "no snapshotting,
        // just query the last session" rule the app follows once you're using it.
        var lastLogged: [String: [(Double, Int)]] = [:]
        var sessionCount: [String: Int] = [:]
        var planIndex = 0
        var cursor = historyStart

        while cursor < today {
            let weekday = calendar.component(.weekday, from: cursor) // 1=Sun...7=Sat
            if weekday == 2 || weekday == 4 || weekday == 6 { // Mon / Wed / Fri
                let plan = plans[planIndex % plans.count]
                planIndex += 1

                let startedAt = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: cursor) ?? cursor
                let workout = Workout(name: plan.routine.name, startedAt: startedAt, routine: plan.routine)
                context.insert(workout)

                for (position, item) in plan.exercises.enumerated() {
                    let (exercise, sets, targetReps, baseWeight) = item
                    let n = sessionCount[exercise.name, default: 0]
                    let progressedWeight = (baseWeight + Double(n / 3) * 2.5).rounded(toNearest: 1.25)
                    let ghosts = lastLogged[exercise.name] ?? Array(repeating: (progressedWeight, targetReps), count: sets)

                    let we = WorkoutExercise(position: position, exercise: exercise, machineNote: exercise.lastMachineNote, workout: workout)
                    context.insert(we)

                    var thisSession: [(Double, Int)] = []
                    for setIndex in 0..<sets {
                        let ghost = setIndex < ghosts.count ? ghosts[setIndex] : (progressedWeight, targetReps)
                        let isLastSet = setIndex == sets - 1
                        let loggedReps = max(1, targetReps - (isLastSet ? Int.random(in: 0...2) : 0))
                        let set = WorkoutSet(position: setIndex, ghostWeight: ghost.0, ghostReps: ghost.1)
                        set.weight = progressedWeight
                        set.reps = loggedReps
                        set.done = true
                        set.completedAt = startedAt.addingTimeInterval(Double(setIndex) * 180)
                        context.insert(set)
                        we.sets.append(set)
                        thisSession.append((progressedWeight, loggedReps))
                    }
                    lastLogged[exercise.name] = thisSession
                    sessionCount[exercise.name] = n + 1
                }
                workout.endedAt = startedAt.addingTimeInterval(Double.random(in: 45...60) * 60)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? today
        }
    }
}

private extension Double {
    func rounded(toNearest step: Double) -> Double {
        (self / step).rounded() * step
    }
}
