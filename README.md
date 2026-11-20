# Klappuhr – Flip Clock für den iOS-StandBy-Modus from Sarah with Claude 💖

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

## Automatische Erneuerung (kostenloser Account)

`scripts/klappuhr-renew.sh` hält die 7-Tage-Signatur am Leben. Ein launchd-Job startet es stündlich.
Bleiben weniger als 30 Stunden Gültigkeit, räumt es die alten Profile weg, baut die App mit frischem Profil
(`xcodebuild -allowProvisioningUpdates`) und installiert sie per WLAN (`xcrun devicectl`).
Bei Erfolg und bei Fehlern kommt eine macOS-Mitteilung, Fehler höchstens alle 6 Stunden.

```sh
scripts/install-launchd.sh            # Job einrichten
scripts/klappuhr-renew.sh --force     # sofort erneuern
tail ~/Library/Logs/Klappuhr/renew.log
```

Vorher `scripts/config.local.example` nach `scripts/config.local` kopieren und die Geräte-ID eintragen. Die Bundle-ID steht oben in `scripts/klappuhr-renew.sh`.
Voraussetzungen: Mac eingeschaltet und angemeldet, iPhone im selben WLAN, Apple-Account in Xcode angemeldet.
