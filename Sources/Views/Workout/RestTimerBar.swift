import SwiftUI

/// Floats above the overview or focus card whenever a rest countdown is
/// running — same component either way, only its bottom offset differs.
struct RestTimerBar: View {
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("REST").font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(Theme.textSecondary)
                Text(Analytics.formatElapsed(session.restRemaining))
                    .font(.numeral(30))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                pill("−10") { session.adjustRest(-10) }
                pill("+10") { session.adjustRest(10) }
                pill("Skip") { session.skipRest() }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(Theme.accent).frame(width: geo.size.width * session.restProgress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x24_24_28))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
    }

    private func pill(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
