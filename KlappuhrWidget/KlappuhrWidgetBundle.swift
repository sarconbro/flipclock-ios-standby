import SwiftUI
import WidgetKit

/// Entry point of the widget extension. Registers both widgets.
@main
struct KlappuhrWidgetBundle: WidgetBundle {
    var body: some Widget {
        HoursWidget()
        MinutesWidget()
    }
}
