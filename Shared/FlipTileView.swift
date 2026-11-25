import SwiftUI

/// A single flip-clock card in the style of Fliqlo:
/// a dark grey, rounded, square tile with large light digits
/// (stretched vertically like classic flip-clock numerals) and a thin hinge line in the middle.
///
/// This file belongs to BOTH targets (app and widget extension), so the preview
/// inside the app looks exactly like the widget.
struct FlipTileView: View {

    /// Rendering style.
    /// - standard: regular colours (Home Screen, StandBy during the day)
    /// - vibrant:  the system tints the widget itself (StandBy night mode = red,
    ///             tinted Home Screen). Only luminance matters in this mode.
    enum Style {
        case standard
        case vibrant
    }

    /// What the tile shows.
    enum Content {
        /// A fixed value, e.g. 7 → "07". Changes with a rolling animation.
        case value(Int)
        /// Live seconds that iOS itself advances every second.
        case liveSeconds(Date)
    }

    // MARK: Appearance tuning

    /// Font size relative to the tile height.
    static let fontScale: CGFloat = 0.69
    /// How much the digits are stretched vertically (1 = not at all).
    static let digitStretch: CGFloat = 1.36

    let content: Content
    var style: Style = .standard

    init(value: Int, style: Style = .standard) {
        self.content = .value(value)
        self.style = style
    }

    init(liveSecondsAt date: Date, style: Style = .standard) {
        self.content = .liveSeconds(date)
        self.style = style
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)

            ZStack {
                // 1) The tile
                RoundedRectangle(cornerRadius: side * 0.13, style: .continuous)
                    .fill(tileFill)

                // 2) The digits
                digits
                    .font(.system(size: side * Self.fontScale, weight: .heavy))
                    .monospacedDigit()                 // equal-width digits → no jiggling
                    .foregroundStyle(digitColor)
                    .lineLimit(1)
                    .scaleEffect(x: 1, y: Self.digitStretch)
                    .offset(y: -side * 0.025)          // sit slightly above centre

                // 3) The thin hinge line
                Rectangle()
                    .fill(lineColor)
                    .frame(height: max(1, side * 0.012))
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private var digits: some View {
        switch content {
        case .value(let value):
            Text(String(format: "%02d", value))
                // Smooth change: the digits roll instead of jumping.
                .contentTransition(.numericText(value: Double(value)))
        case .liveSeconds(let date):
            LiveSeconds(date: date)
        }
    }

    // MARK: - Colours

    private var tileFill: Color {
        switch style {
        case .standard: Color(white: 0.11)
        case .vibrant:  Color.white.opacity(0.14) // becomes a very dark red in night mode
        }
    }

    private var digitColor: Color {
        switch style {
        case .standard: Color(red: 0.88, green: 0.88, blue: 0.89)
        case .vibrant:  Color.white            // brightest level → readable at night
        }
    }

    private var lineColor: Color {
        switch style {
        case .standard: Color.black
        case .vibrant:  Color.black.opacity(0.9)
        }
    }
}

/// Live seconds display that iOS updates every second by itself,
/// even inside a widget, which we may otherwise only redraw about once a minute.
///
/// Trick: a stopwatch started at the top of the hour shows "MM:SS", which is
/// exactly the current time without the hour. We keep only the last two digits
/// visible and clip the rest.
private struct LiveSeconds: View {
    let date: Date

    var body: some View {
        let hourStart = Calendar.current.dateInterval(of: .hour, for: date)?.start ?? date

        // An invisible "00" defines the width: exactly two digits.
        Text(verbatim: "00")
            .hidden()
            .overlay(alignment: .trailing) {
                // In a widget, iOS draws the running timer itself and reserves its own,
                // wider frame for it (left-aligned by default). So: give it a fixed,
                // very wide frame and right-align the text explicitly. Only the right
                // edge stays visible.
                Text(timerInterval: hourStart...hourStart.addingTimeInterval(3600),
                     countsDown: false)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .frame(width: 2000, alignment: .trailing)
            }
            .clipShape(Rectangle())
    }
}

/// The complete clock layout:
/// [hours] [minutes] [small seconds, bottom-aligned].
/// Used by the in-app preview; the widgets recreate the same layout
/// split across two halves.
struct FlipClockRow: View {
    let date: Date

    /// Size of the seconds tile relative to a large tile.
    static let secondsScale: CGFloat = 0.3

    var body: some View {
        let calendar = Calendar.current
        GeometryReader { geo in
            // Width = 2 large tiles + 1 small tile + 2 gaps (11 % of a tile each)
            let tile = geo.size.width / (2 + Self.secondsScale + 0.22)
            HStack(alignment: .bottom, spacing: tile * 0.11) {
                FlipTileView(value: calendar.component(.hour, from: date))
                    .frame(width: tile, height: tile)
                FlipTileView(value: calendar.component(.minute, from: date))
                    .frame(width: tile, height: tile)
                FlipTileView(liveSecondsAt: date)
                    .frame(width: tile * Self.secondsScale, height: tile * Self.secondsScale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(2 + Self.secondsScale + 0.22, contentMode: .fit)
    }
}

#Preview {
    FlipClockRow(date: .now)
        .padding()
        .background(.black)
}
