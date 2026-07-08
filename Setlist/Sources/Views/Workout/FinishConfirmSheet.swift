import SwiftUI

struct FinishConfirmSheet: View {
    let session: WorkoutSession

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { session.cancelFinish() }
            VStack(alignment: .leading, spacing: 16) {
                Text("Finish workout?").font(.numeral(24)).textCase(.uppercase)

                if let summary = session.finishSummary {
                    VStack(spacing: 10) {
                        row("Duration", summary.duration)
                        row("Sets completed", String(summary.setsDone))
                        row("Volume", "\(Int(summary.volume)) kg")
                    }
                    if let pr = summary.prExerciseName {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill").font(.system(size: 13)).foregroundStyle(Theme.accent)
                            Text("New PR — \(pr)").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Theme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                HStack(spacing: 10) {
                    Button("Keep going") { session.cancelFinish() }.buttonStyle(SetlistSecondaryButtonStyle())
                    Button("Finish") { session.confirmFinish() }.buttonStyle(SetlistPrimaryButtonStyle())
                }
            }
            .padding(20)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(24)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(.numeral(17, weight: .bold))
        }
    }
}
