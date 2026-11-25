import SwiftUI
import WidgetKit

// MARK: - View shared by both widgets

struct ClockWidgetView: View {
    let entry: ClockEntry
    let unit: ClockUnit

    /// .fullColor = regular colours.
    /// .vibrant / .accented = the system tints the widget (StandBy night mode, tinted Home Screen).
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        // 24-hour format: .hour always returns 0–23, regardless of the locale's 12/24 h setting.
        let value = Calendar.current.component(unit.calendarComponent, from: entry.date)
        let style: FlipTileView.Style = renderingMode == .fullColor ? .standard : .vibrant

        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let tile = side * 0.65                          // large tile
            let small = tile * FlipClockRow.secondsScale    // seconds tile
            let inset = side * 0.04                         // distance to the screen centre

            switch unit {
            case .hours:
                // Hours tile pushed right (towards the centre)
                FlipTileView(value: value, style: style)
                    .frame(width: tile, height: tile)
                    .padding(.trailing, inset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            case .minutes:
                // Minutes tile pushed left (towards the centre), small seconds next to it, bottom-aligned
                HStack(alignment: .bottom, spacing: tile * 0.11) {
                    FlipTileView(value: value, style: style)
                        .frame(width: tile, height: tile)
                    FlipTileView(liveSecondsAt: entry.date, style: style)
                        .frame(width: small, height: small)
                }
                .padding(.leading, inset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .widgetAccentable()   // in tinted mode the tiles take the accent colour
        // Black background. StandBy hides it, but the screen is black there anyway.
        .containerBackground(Color.black, for: .widget)
    }
}

// MARK: - Widget 1: hours

struct HoursWidget: Widget {
    // Keep this identifier unchanged: renaming it removes widgets users already placed.
    let kind = "KlappuhrStunden"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider(unit: .hours)) { entry in
            ClockWidgetView(entry: entry, unit: .hours)
        }
        .configurationDisplayName("Hours")
        .description("Shows the hours. Place it on the left in StandBy.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()   // own margins instead of the default ones → larger tile
    }
}

// MARK: - Widget 2: minutes

struct MinutesWidget: Widget {
    // Keep this identifier unchanged: renaming it removes widgets users already placed.
    let kind = "KlappuhrMinuten"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider(unit: .minutes)) { entry in
            ClockWidgetView(entry: entry, unit: .minutes)
        }
        .configurationDisplayName("Minutes")
        .description("Shows the minutes and seconds. Place it on the right in StandBy.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Xcode previews (canvas)

#Preview("Hours", as: .systemSmall) {
    HoursWidget()
} timeline: {
    ClockEntry(date: .now)
    ClockEntry(date: .now.addingTimeInterval(3600))
}

#Preview("Minutes", as: .systemSmall) {
    MinutesWidget()
} timeline: {
    ClockEntry(date: .now)
    ClockEntry(date: .now.addingTimeInterval(60))
    ClockEntry(date: .now.addingTimeInterval(120))
}
