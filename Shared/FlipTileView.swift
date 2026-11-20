import SwiftUI

/// Eine einzelne Klappkarte im Fliqlo-Stil:
/// dunkelgraue, abgerundete, quadratische Kachel, große helle Ziffern
/// (in die Höhe gestreckt wie klassische Klappzahlen), feine Trennlinie in der Mitte.
///
/// Diese Datei gehört zu BEIDEN Targets (App und Widget), damit die Vorschau
/// in der App exakt so aussieht wie das Widget.
struct FlipTileView: View {

    /// Darstellungsart.
    /// - standard: normale Farben (Homescreen, StandBy tagsüber)
    /// - vibrant:  das System färbt selbst ein (StandBy-Nachtmodus = rot,
    ///             getönter Homescreen). Dann zählt nur die Helligkeit.
    enum Style {
        case standard
        case vibrant
    }

    /// Was auf der Kachel steht.
    enum Content {
        /// Fester Wert, z. B. 7 → „07“. Wechselt mit Roll-Animation.
        case value(Int)
        /// Laufende Sekunden, die iOS selbst jede Sekunde weiterzählt.
        case liveSeconds(Date)
    }

    // MARK: Stellschrauben fürs Aussehen

    /// Schriftgröße im Verhältnis zur Kachelhöhe.
    static let fontScale: CGFloat = 0.69
    /// Wie stark die Ziffern in die Höhe gezogen werden (1 = gar nicht).
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
                // 1) Die Kachel
                RoundedRectangle(cornerRadius: side * 0.13, style: .continuous)
                    .fill(tileFill)

                // 2) Die Ziffern
                digits
                    .font(.system(size: side * Self.fontScale, weight: .heavy))
                    .monospacedDigit()                 // alle Ziffern gleich breit → kein Wackeln
                    .foregroundStyle(digitColor)
                    .lineLimit(1)
                    .scaleEffect(x: 1, y: Self.digitStretch)
                    .offset(y: -side * 0.025)          // etwas höher, wie im Referenzbild

                // 3) Die feine Trennlinie (der Klappspalt)
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
                // Weicher Wechsel: die Ziffern rollen statt hart zu springen.
                .contentTransition(.numericText(value: Double(value)))
        case .liveSeconds(let date):
            LiveSeconds(date: date)
        }
    }

    // MARK: - Farben (abgenommen vom Referenz-Screenshot)

    private var tileFill: Color {
        switch style {
        case .standard: Color(white: 0.11)
        case .vibrant:  Color.white.opacity(0.14) // ergibt im Nachtmodus ein sehr dunkles Rot
        }
    }

    private var digitColor: Color {
        switch style {
        case .standard: Color(red: 0.88, green: 0.88, blue: 0.89)
        case .vibrant:  Color.white            // hellste Stufe → gut lesbar, auch nachts
        }
    }

    private var lineColor: Color {
        switch style {
        case .standard: Color.black
        case .vibrant:  Color.black.opacity(0.9)
        }
    }
}

/// Laufende Sekundenanzeige, die iOS selbst jede Sekunde aktualisiert,
/// auch im Widget, das wir sonst nur einmal pro Minute neu zeichnen dürfen.
///
/// Trick: Eine Stoppuhr, die zur vollen Stunde gestartet ist, zeigt „MM:SS“,
/// also genau die aktuelle Uhrzeit ohne Stunden. Wir lassen davon nur die
/// letzten zwei Ziffern sichtbar und schneiden den Rest ab.
private struct LiveSeconds: View {
    let date: Date

    var body: some View {
        let hourStart = Calendar.current.dateInterval(of: .hour, for: date)?.start ?? date

        // Unsichtbares „00“ legt die Breite fest: genau zwei Ziffern.
        Text("00")
            .hidden()
            .overlay(alignment: .trailing) {
                // Im Widget zeichnet iOS die laufende Zeit selbst und reserviert
                // dafür eine eigene, breitere Fläche (Text darin standardmäßig
                // linksbündig). Darum: feste, sehr breite Fläche, Text darin
                // ausdrücklich rechtsbündig. Sichtbar bleibt nur der rechte Rand.
                Text(timerInterval: hourStart...hourStart.addingTimeInterval(3600),
                     countsDown: false)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .frame(width: 2000, alignment: .trailing)
            }
            .clipShape(Rectangle())
    }
}

/// Die komplette Uhr-Anordnung wie im Referenzbild:
/// [Stunden] [Minuten] [kleine Sekunden unten bündig].
/// Wird in der App-Vorschau benutzt; die Widgets bauen dieselbe Anordnung
/// auf zwei Hälften verteilt nach.
struct FlipClockRow: View {
    let date: Date

    /// Größe der Sekunden-Kachel im Verhältnis zur großen Kachel.
    static let secondsScale: CGFloat = 0.3

    var body: some View {
        let calendar = Calendar.current
        GeometryReader { geo in
            // Breite = 2 große Kacheln + 1 kleine + 2 Lücken (je 11 % einer Kachel)
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
