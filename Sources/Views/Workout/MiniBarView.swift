import SwiftUI

/// The Spotify-style now-playing bar: visible on every tab and even over the
/// workout overview itself, any time a workout is active and focus mode isn't
/// open. Tapping it jumps straight back into the current exercise's focus card.
struct MiniBarView: View {
    let session: WorkoutSession

    private var title: String {
        session.currentExercise?.exercise?.name ?? "Workout done — tap to finish"
    }

    private var subtitle: (text: String, color: Color) {
        if session.isPaused {
            return ("Paused · \(Analytics.formatElapsed(session.elapsedSeconds))", Theme.textSecondary)
        } else if session.isResting {
            return ("Rest · \(Analytics.formatElapsed(session.restRemaining))", Theme.accent)
        } else if let cur = session.currentExercise {
            let doneN = cur.doneCount
            return ("Set \(min(doneN + 1, cur.sets.count)) of \(cur.sets.count) · \(Analytics.formatElapsed(session.elapsedSeconds))", Theme.textSecondary)
        } else {
            return ("Tap to finish · \(Analytics.formatElapsed(session.elapsedSeconds))", Theme.accent)
        }
    }

    private var showSkip: Bool { SettingsStore.shared.restTimerEnabled && session.isResting }

    var body: some View {
        Button { session.expandToCurrent() } label: {
            HStack(spacing: 12) {
                SetlistMark(size: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    Text(subtitle.text).font(.numeral(13, weight: .semibold)).foregroundStyle(subtitle.color)
                }
                Spacer(minLength: 0)
                if showSkip {
                    Button { session.skipRest() } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .frame(height: Theme.miniBarHeight)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .overlay(alignment: .bottomLeading) {
                if session.isResting {
                    GeometryReader { geo in
                        Rectangle().fill(Theme.accent).frame(width: geo.size.width * session.restProgress, height: 2)
                    }
                    .frame(height: 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.textPrimary)
    }
}
