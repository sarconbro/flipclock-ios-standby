import SwiftUI
import WidgetKit

/// Einstiegspunkt der Widget-Extension. Hier sind beide Widgets angemeldet.
@main
struct KlappuhrWidgetBundle: WidgetBundle {
    var body: some Widget {
        HoursWidget()
        MinutesWidget()
    }
}
