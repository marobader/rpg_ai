# Fantasy Skill-RPG (Roblox)

Ein Roblox-RPG im RuneScape-Stil: Spieler leveln einzelne Skills in einer Fantasy-Welt,
kämpfen in Echtzeit gegen Mobs, sammeln & craften Items, erledigen Quests und reisen
durch Dimensionen.

Entwickelt zusammen mit Claude Code direkt in Roblox Studio.

## 📖 Design

Das vollständige Game-Design-Dokument liegt unter [docs/GameDesign.md](docs/GameDesign.md).

## 🗂️ Projektstruktur

```
RPG.rbxlx                 ← Der Roblox-Platz (enthält ALLES: Code + Welt)
docs/GameDesign.md        ← Game-Design-Dokument
src/                      ← Lesbare, versionierte Kopie aller Scripts (Rojo-Struktur)
```

> **Wichtig:** Die Datei `RPG.rbxlx` ist die maßgebliche Projektdatei — sie enthält
> den gesamten Code UND die Welt. Zum Öffnen einfach in Roblox Studio laden.
>
> Der Ordner `src/` ist eine automatisch gepflegte, lesbare Spiegelung des Codes
> (zum Durchschauen & für saubere git-Diffs). Die Dateiendungen folgen der
> Rojo-Konvention: `*.server.luau` (Server-Script), `*.client.luau` (LocalScript),
> `*.luau` (ModuleScript).

## 🎮 Aktueller Stand (Prototyp)

Dimension **Flüsterwald** + Dorf-Hub „Eichhain", mit den Skills **Schwert**,
**Holzfällen** und **Bergbau**.

- ✅ Skill-System (12 Skills definiert, je Level 1–50) + Gesamtlevel
- ✅ XP-Kurve, Datenspeicherung (DataStore mit Studio-Fallback)
- ✅ Welt: Dorf + Wald, verbunden per Portalen
- ✅ Ressourcen: Bäume fällen, Erz abbauen (mit Level-Anforderungen & Respawn)
- ✅ Echtzeit-Kampf mit Schwert + Ausweichen, 3 Gegnertypen mit KI
- ✅ Inventar-UI mit Raritätsfarben, Gold, Pop-up-Meldungen
- ⬜ Quests, Skill-/XP-Oberfläche, Atmosphäre (in Arbeit)

## 🕹️ Steuerung

- **Linksklick** – Schwerthieb
- **Q** – Ausweichen (kurze Unverwundbarkeit)
- **E** (halten) – Ressourcen abbauen (an Bäumen/Felsen)
- **I** oder **Tab** – Inventar öffnen
