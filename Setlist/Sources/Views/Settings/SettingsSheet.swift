import SwiftUI

struct SettingsSheet: View {
    private let store = SettingsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings").font(.numeral(24)).textCase(.uppercase).padding(.bottom, 12)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest timer").font(.system(size: 15, weight: .semibold))
                    Text("Start automatically after each set").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { store.restTimerEnabled }, set: { store.restTimerEnabled = $0 }))
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairlineStrong).frame(height: 0.5) }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest duration")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(store.restTimerEnabled ? Color.white : Color.white.opacity(0.35))
                    Text("Between sets").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                stepButton("minus") { store.restDuration = max(10, store.restDuration - 10) }
                Text("\(store.restDuration) s")
                    .font(.numeral(24))
                    .frame(minWidth: 58)
                    .foregroundStyle(store.restTimerEnabled ? Theme.accent : Color.white.opacity(0.3))
                stepButton("plus") { store.restDuration = min(300, store.restDuration + 10) }
            }
            .padding(.vertical, 14)

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .background(Theme.card.ignoresSafeArea())
    }

    private func stepButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
