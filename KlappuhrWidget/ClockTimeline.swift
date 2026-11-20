import WidgetKit

/// Welche Hälfte der Uhr ein Widget zeigt.
enum ClockUnit {
    case hours
    case minutes

    var calendarComponent: Calendar.Component {
        self == .hours ? .hour : .minute
    }
}

/// Ein „Eintrag“ in der Zeitleiste: ein Zeitpunkt, ab dem das Widget neu gezeichnet wird.
struct ClockEntry: TimelineEntry {
    let date: Date
}

/// Liefert WidgetKit im Voraus eine Liste von Zeitpunkten.
///
/// Widgets laufen nicht dauerhaft. iOS holt sich stattdessen eine Zeitleiste
/// und zeichnet das Widget genau zu jedem Eintrag neu. Deshalb legen wir für
/// jede volle Minute (bzw. Stunde) einen Eintrag an.
struct ClockProvider: TimelineProvider {
    let unit: ClockUnit

    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(ClockEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let component = unit.calendarComponent

        // Beginn der aktuellen Minute/Stunde, z. B. 14:37:00
        let start = calendar.dateInterval(of: component, for: now)?.start ?? now

        // Minuten: 3 Stunden im Voraus (180 Einträge) → iOS muss nur ca. 8× am Tag nachladen.
        // Stunden: 24 Einträge → einmal pro Tag nachladen.
        let count = unit == .hours ? 24 : 180

        var entries = [ClockEntry(date: now)]
        for step in 1...count {
            if let date = calendar.date(byAdding: component, value: step, to: start) {
                entries.append(ClockEntry(date: date))
            }
        }

        // .atEnd = nach dem letzten Eintrag holt sich iOS eine neue Zeitleiste.
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
