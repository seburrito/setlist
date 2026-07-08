import SwiftUI

struct TabBarView: View {
    let tab: AppTab
    var onSelect: (AppTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.home, systemName: "house.fill", label: "Home")
            item(.library, systemName: "rectangle.grid.1x2.fill", label: "Library")
            item(.progress, systemName: "chart.bar.fill", label: "Progress")
            item(.history, systemName: "clock.fill", label: "History")
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .frame(height: Theme.tabBarHeight)
        .background(
            ZStack {
                Theme.background.opacity(0.7)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairlineStrong).frame(height: 0.5)
        }
    }

    private func item(_ value: AppTab, systemName: String, label: String) -> some View {
        let isOn = tab == value
        return VStack(spacing: 3) {
            Image(systemName: systemName).font(.system(size: 22))
            Text(label).font(.system(size: 10, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(isOn ? Theme.accent : Theme.textSecondary)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(value) }
    }
}
