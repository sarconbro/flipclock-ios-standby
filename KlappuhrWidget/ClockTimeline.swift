import WidgetKit

/// Which half of the clock a widget shows.
enum ClockUnit {
    case hours
    case minutes

    var calendarComponent: Calendar.Component {
        self == .hours ? .hour : .minute
    }
}

/// One entry in the timeline: a point in time from which the widget is redrawn.
struct ClockEntry: TimelineEntry {
    let date: Date
}

/// Hands WidgetKit a list of future points in time.
///
/// Widgets don't run continuously. Instead, iOS asks for a timeline up front
/// and redraws the widget at each entry. So we create one entry for every
/// full minute (or hour).
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

        // Start of the current minute/hour, e.g. 14:37:00
        let start = calendar.dateInterval(of: component, for: now)?.start ?? now

        // Minutes: 3 hours ahead (180 entries) → iOS only reloads about 8 times a day.
        // Hours: 24 entries → one reload per day.
        let count = unit == .hours ? 24 : 180

        var entries = [ClockEntry(date: now)]
        for step in 1...count {
            if let date = calendar.date(byAdding: component, value: step, to: start) {
                entries.append(ClockEntry(date: date))
            }
        }

        // .atEnd = after the last entry, iOS requests a new timeline.
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
