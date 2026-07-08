import SwiftUI

/// The #1A1A1E rounded-16 card used everywhere.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = Theme.radiusLarge
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    func setlistCard(padding: CGFloat = 16, radius: CGFloat = Theme.radiusLarge) -> some View {
        modifier(CardBackground(padding: padding, radius: radius))
    }
}

/// The pill-style segmented control used for tab-within-tab switches
/// (Exercises/Routines, By muscle group/By exercise, 4/8/12 weeks).
struct PillSegmented<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var background: Color = Theme.card
    var selected: Color = Color(hex: 0x2C_2C_31)
    var font: Font = .system(size: 14, weight: .semibold)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { value, label in
                let isOn = value == selection
                Text(label)
                    .font(font)
                    .foregroundStyle(isOn ? Theme.textPrimary : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isOn ? selected : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { selection = value } }
            }
        }
        .padding(3)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Dashed "+ New thing" affordance (add exercise, new routine, new exercise…).
struct DashedAddButton: View {
    let title: String
    var height: CGFloat = 48
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.textPrimary.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Color.white.opacity(0.18))
            )
        }
        .buttonStyle(.plain)
    }
}

/// A minimal weekly-volume sparkline, styled like the prototype's inline SVG polyline.
struct Sparkline: View {
    let values: [Double]
    var color: Color = Theme.accent
    var lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let mn = values.min() ?? 0
            let mx = values.max() ?? 1
            let span = max(mx - mn, 0.0001)
            Path { path in
                for (i, v) in values.enumerated() {
                    let x = values.count > 1 ? geo.size.width * CGFloat(i) / CGFloat(values.count - 1) : geo.size.width
                    let y = geo.size.height - geo.size.height * CGFloat((v - mn) / span)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }
}

/// The lime "NOW" / status chip used on the overview card and focus header.
struct StatusChip: View {
    let text: String
    let filled: Bool
    let outlined: Bool
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy))
            .tracking(1)
            .foregroundStyle(filled ? Theme.onAccent : Theme.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(filled ? Theme.accent : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(outlined ? Color.white.opacity(0.25) : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

/// Small round checkmark used for completed sets everywhere.
struct CheckBadge: View {
    let done: Bool
    var size: CGFloat = 30
    var body: some View {
        Circle()
            .fill(done ? Theme.accent : .clear)
            .overlay(
                Circle().strokeBorder(done ? .clear : Color.white.opacity(0.22), lineWidth: 1.5)
            )
            .overlay {
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(Theme.onAccent)
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(done ? 1.05 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: done)
    }
}

/// Small dot used for calendar cells, split legend, and history rows.
struct SplitDot: View {
    let color: Color
    var size: CGFloat = 8
    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
    }
}

/// The Setlist "equalizer bars" logo mark.
struct SetlistMark: View {
    var size: CGFloat = 22
    var color: Color = Theme.accent
    var body: some View {
        HStack(alignment: .bottom, spacing: size * 0.11) {
            bar(heightFraction: 0.36)
            bar(heightFraction: 0.59)
            bar(heightFraction: 0.82)
        }
        .frame(width: size, height: size, alignment: .bottom)
    }
    private func bar(heightFraction: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.1)
            .fill(color)
            .frame(width: size * 0.2, height: size * heightFraction)
    }
}

/// Rounded 12pt icon button used for chevrons/back/gear affordances on dark cards.
struct IconButton: View {
    let systemName: String
    var background: Color = Theme.card
    var foreground: Color = .white.opacity(0.7)
    var size: CGFloat = 38
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
