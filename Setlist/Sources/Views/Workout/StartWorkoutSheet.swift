import SwiftUI
import SwiftData

struct StartWorkoutSheet: View {
    let session: WorkoutSession
    @Binding var isPresented: Bool
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Start workout").font(.numeral(24)).textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(Array(routines.enumerated()), id: \.element.persistentModelID) { index, routine in
                    Button {
                        session.start(routine: routine)
                        isPresented = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.name).font(.system(size: 16, weight: .semibold))
                                Text("\(routine.entries.count) exercise\(routine.entries.count == 1 ? "" : "s")")
                                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textTertiary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textPrimary)
                    .overlay(alignment: .bottom) {
                        if index < routines.count - 1 { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
                    }
                }
            }
            .background(Theme.cardInset)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                session.start(routine: nil)
                isPresented = false
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                    Text("Empty workout").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .foregroundStyle(Color.white.opacity(0.18))
                )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .background(Theme.card.ignoresSafeArea())
    }
}
