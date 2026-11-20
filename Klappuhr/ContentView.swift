import SwiftUI

/// Der einfache Infoscreen der App: Live-Vorschau der Uhr und eine Anleitung.
struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Live-Vorschau: TimelineView zeichnet die Ansicht zu jeder vollen Minute neu.
                TimelineView(.everyMinute) { context in
                    FlipClockRow(date: context.date)
                        .animation(.smooth, value: context.date)
                        .frame(maxWidth: 480)
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Klappuhr")
                        .font(.largeTitle.bold())
                    Text("Zwei Widgets für den StandBy-Modus: eines für die Stunden, eines für die Minuten.")
                        .foregroundStyle(.secondary)
                }

                InfoSection(title: "So richtest du StandBy ein", steps: [
                    "Einstellungen → StandBy → StandBy einschalten.",
                    "iPhone sperren, quer hinlegen und ans Ladegerät anschließen.",
                    "Nach links wischen, bis die Ansicht mit zwei Widget-Stapeln kommt.",
                    "Linken Stapel gedrückt halten → „+“ → Klappuhr → „Stunden“ hinzufügen.",
                    "Rechten Stapel gedrückt halten → „+“ → Klappuhr → „Minuten“ hinzufügen.",
                    "Die anderen Widgets im Stapel entfernen, damit nichts weiterblättert.",
                ])

                InfoSection(title: "Nachtmodus", steps: [
                    "Einstellungen → StandBy → Nachtmodus einschalten.",
                    "Im Dunkeln färbt iOS die Uhr automatisch rot ein.",
                ])

                Text("Hinweis: Mit einem kostenlosen Apple-Account läuft die App nur 7 Tage und muss danach neu aus Xcode installiert werden.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

/// Eine Überschrift mit nummerierten Schritten.
private struct InfoSection: View {
    let title: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1).")
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
