import SwiftUI

/// The app's simple info screen: a live preview of the clock and setup instructions.
struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Live preview: TimelineView redraws the view at every full minute.
                TimelineView(.everyMinute) { context in
                    FlipClockRow(date: context.date)
                        .animation(.smooth, value: context.date)
                        .frame(maxWidth: 480)
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: "Klappuhr")
                        .font(.largeTitle.bold())
                    Text("A flip clock for StandBy: one widget for the hours, one for the minutes and seconds.")
                        .foregroundStyle(.secondary)
                }

                InfoSection(title: "Setting up StandBy", steps: [
                    "Settings → StandBy → turn on StandBy.",
                    "Lock your iPhone, lay it on its side and connect it to a charger.",
                    "Swipe left until you see the view with two widget stacks.",
                    "Touch and hold the left stack → “+” → Klappuhr → add “Hours”.",
                    "Touch and hold the right stack → “+” → Klappuhr → add “Minutes”.",
                    "Remove the other widgets from both stacks so nothing rotates away.",
                ])

                InfoSection(title: "Night mode", steps: [
                    "Settings → StandBy → turn on Night Mode.",
                    "In the dark, iOS automatically tints the clock red.",
                ])

                Text("Note: with a free Apple account, the app only runs for 7 days and then has to be reinstalled from Xcode.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

/// A heading with numbered steps.
private struct InfoSection: View {
    let title: LocalizedStringKey
    let steps: [LocalizedStringKey]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(verbatim: "\(index + 1).")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Text(step)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
