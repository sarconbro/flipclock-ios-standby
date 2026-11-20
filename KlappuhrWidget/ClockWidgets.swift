import SwiftUI
import WidgetKit

// MARK: - Ansicht, die beide Widgets teilen

struct ClockWidgetView: View {
    let entry: ClockEntry
    let unit: ClockUnit

    /// .fullColor = normale Farben.
    /// .vibrant / .accented = das System färbt ein (StandBy-Nachtmodus, getönter Homescreen).
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        // 24-h-Format: .hour liefert immer 0–23, unabhängig von der Spracheinstellung.
        let value = Calendar.current.component(unit.calendarComponent, from: entry.date)
        let style: FlipTileView.Style = renderingMode == .fullColor ? .standard : .vibrant

        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let tile = side * 0.65                          // große Kachel
            let small = tile * FlipClockRow.secondsScale    // Sekunden-Kachel
            let inset = side * 0.04                         // Abstand zur Bildschirmmitte

            switch unit {
            case .hours:
                // Stunden-Kachel nach rechts (zur Mitte) gerückt
                FlipTileView(value: value, style: style)
                    .frame(width: tile, height: tile)
                    .padding(.trailing, inset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            case .minutes:
                // Minuten-Kachel nach links (zur Mitte), daneben kleine Sekunden, unten bündig
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
        .widgetAccentable()   // im getönten Modus bekommen die Kacheln die Akzentfarbe
        // Schwarzer Hintergrund. In StandBy blendet iOS ihn aus, dort ist es ohnehin schwarz.
        .containerBackground(Color.black, for: .widget)
    }
}

// MARK: - Widget 1: Stunden

struct HoursWidget: Widget {
    let kind = "KlappuhrStunden"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider(unit: .hours)) { entry in
            ClockWidgetView(entry: entry, unit: .hours)
        }
        .configurationDisplayName("Klappuhr – Stunden")
        .description("Zeigt die Stunden. Für StandBy links platzieren.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()   // eigene Ränder statt der Standard-Ränder → größere Kachel
    }
}

// MARK: - Widget 2: Minuten

struct MinutesWidget: Widget {
    let kind = "KlappuhrMinuten"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider(unit: .minutes)) { entry in
            ClockWidgetView(entry: entry, unit: .minutes)
        }
        .configurationDisplayName("Klappuhr – Minuten")
        .description("Zeigt die Minuten. Für StandBy rechts platzieren.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Vorschauen in Xcode (Canvas)

#Preview("Stunden", as: .systemSmall) {
    HoursWidget()
} timeline: {
    ClockEntry(date: .now)
    ClockEntry(date: .now.addingTimeInterval(3600))
}

#Preview("Minuten", as: .systemSmall) {
    MinutesWidget()
} timeline: {
    ClockEntry(date: .now)
    ClockEntry(date: .now.addingTimeInterval(60))
    ClockEntry(date: .now.addingTimeInterval(120))
}
