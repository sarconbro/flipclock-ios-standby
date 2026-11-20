# Klappuhr – Flip Clock für den iOS-StandBy-Modus

Eine Klappuhr im Fliqlo-Stil als WidgetKit-Widgets für den StandBy-Modus des iPhones
(quer, gesperrt, beim Laden).

- **Stunden-Widget** und **Minuten-Widget** (je `systemSmall`), für die beiden StandBy-Stapel
- Kleine **Sekunden-Kachel** neben den Minuten, die iOS selbst live weiterzählt
- 24-h-Format, schwarzer Hintergrund, dunkelgraue Kacheln, gestreckte Ziffern, Trennlinie
- Weicher Ziffernwechsel per `contentTransition(.numericText)`
- StandBy-Nachtmodus: iOS färbt die Uhr automatisch rot ein (`widgetRenderingMode`)
- Die App selbst zeigt nur eine Live-Vorschau und eine Anleitung

Voraussetzung: iOS 17 oder neuer, Xcode 26 oder neuer.

## Projektaufbau

| Ordner | Inhalt |
|---|---|
| `Klappuhr/` | App (Infoscreen) |
| `KlappuhrWidget/` | Widget-Extension: Zeitleiste und die beiden Widgets |
| `Shared/` | `FlipTileView`: die Kachel, von App und Widget gemeinsam genutzt |

## Bauen und installieren

1. `Klappuhr.xcodeproj` in Xcode öffnen.
2. Bei beiden Targets (*Klappuhr*, *KlappuhrWidgetExtension*) unter *Signing & Capabilities* das eigene Team wählen.
   Falls nötig, die Bundle-IDs in eigene ändern.
3. iPhone wählen und ▶︎ drücken.

Mit einem kostenlosen Apple-Account (Personal Team) läuft die Installation 7 Tage lang.

## In StandBy einrichten

1. iPhone sperren, quer hinlegen, ans Ladegerät.
2. Nach links wischen bis zur Ansicht mit zwei Widget-Stapeln.
3. Links „Klappuhr – Stunden“, rechts „Klappuhr – Minuten“ hinzufügen.
