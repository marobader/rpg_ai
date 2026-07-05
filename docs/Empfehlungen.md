# Empfehlungen & Ausbau-Roadmap

*Analyse der bestehenden Lösung + strukturierte Empfehlungen. Stand: Prototyp mit Dorf „Eichhain" + Dimension Flüsterwald.*

**Legende Aufwand:** 🟢 Quick Win · 🟡 mittel · 🔴 großes Feature

**Architektur-Stärke:** Fast alles ist datengetrieben (`Config/Skills|XP|Items|Resources|Mobs|Quests`). Neue Inhalte = meist neue Config-Einträge, keine neue Logik. Die größten „Enabler" für alles Weitere sind: ein zentrales **Stats/Progression-Modul**, ein **Rezept-/Crafting-System** und ein **Shop-System**.

---

## 1. Animationen
Aktuell: Schwert-Schwung, Dodge-Ghost, Level-Up-Popup, Drop-Schwebe/Dreh, XP-Bar-Tween. Mobs bewegen sich per PivotTo ohne Anim, Ernte ohne Anim.

- 🟢 **Mob-Treffer-Flash** — bei Schaden Körper kurz rot tweenen (nutzt vorhandenes `damageMob`).
- 🟢 **Mob-Angriffs-Lunge** — beim `Winding`-Attribut kurz nach vorn „ausholen" (Tween), macht das Ausweichen lesbar.
- 🟢 **Ernte-Animation** — Werkzeug-Swing beim Fällen/Abbauen (wie Schwert-Swing).
- 🟡 **Baum fällt / Erz zerspringt** — statt Blätter sofort ausblenden: umkippen/schrumpfen + Partikel.
- 🟡 **Schwebende Schadenszahlen** (BillboardGui) bei Treffern.
- 🟡 **Mob-Tod** — Ragdoll-ähnliches Umfallen/Schrumpfen statt Instant-Destroy.
- 🔴 **Echte Humanoid-Animationen** (Walk/Attack/Idle) für Mobs & Spieler-Tools.

## 2. Effekte (VFX + Sound)
Aktuell: Portal-Partikel, Atmosphären-Staub/Sporen, Drop-Licht, Level-Up-Glow. **Sound fehlt fast komplett (größter Immersion-Hebel!).**

- 🟢 **Kampf-SFX** — Schwung, Treffer, Krit (via `search_asset` wie bei der Ambience gefunden).
- 🟢 **Sammel-SFX** — Holz hacken, Erz schlagen, Item-Pickup „Plopp".
- 🟢 **Level-Up-Chime + Partikel-Burst** am Charakter.
- 🟢 **Schwert-Trail** (Trail-Instance an der Klinge) + Treffer-Funken.
- 🟡 **Holzspäne/Steinsplitter-Partikel** beim Ernten.
- 🟡 **Fußschritt-Sounds** je Material.
- 🟡 **Krit-Treffer** visuell (größere Zahl, Flash).

## 3. UI-Elemente
Aktuell: Inventar, Gold, Toasts, Quest-Tracker+Dialog, Skill-Panel, Level-Up-Popup, XP-Bar.

- 🟢 **Stylische Lebensanzeige** (Spieler-HP als HUD-Balken statt Roblox-Default).
- 🟢 **„Neues Gebiet freigeschaltet"-Banner** / Meilenstein-Toasts.
- 🟡 **Item-Tooltips** (Hover: Stats, Rarität, Verkaufspreis).
- 🟡 **Hotbar für Verbrauchsgegenstände** (Tränke schnell nutzen, Tasten 1–5).
- 🟡 **Voll-Questlog** (nicht nur Tracker) + Karten-Marker.
- 🟡 **Ausrüstungs-/Charakter-Panel** (Waffe/Rüstung).
- 🟡 **Einstellungen** (Lautstärke, Grafik).
- 🔴 **Minimap / Kompass** (wichtig mit mehreren Dimensionen).

## 4. Mehr Randomness
Aktuell: feste Loot-Chancen, feste XP, Gold-Range, geseedete Streuung.

- 🟢 **Gewichtete Loot-Tables + seltene Drops** (z. B. 1% mystisches Item von jedem Mob) — `loot`-Config erweitern.
- 🟢 **Kritische Treffer** (Chance auf Extra-Schaden, skaliert mit Skill).
- 🟢 **Node-Ausbeute variabel** (1–3 Holz, seltener „goldener Baum").
- 🟡 **Item-Qualität/Affixe** — gecraftete/gesammelte Items mit Zufalls-Rolls (z. B. Schwert +3–8 Schaden, „Eichenholz (fein)").
- 🟡 **Mob-Varianten** — zufällige Skalierung/Färbung, gelegentliche „Elite" mit Buff + besserer Beute.
- 🟡 **Zufalls-Events** — Wander-Elite, Schatztruhen, Ressourcen-Boom.
- 🟡 **Täglich wechselndes Shop-Sortiment.**

## 5. Viel mehr Items & neue Sammel-Skills
Hier zahlt sich das datengetriebene Design aus: neues Item = Eintrag in `Config/Items`, neuer Knoten = Eintrag in `Config/Resources`.

- 🟡 **Angeln** — Wasser in die Welt (Terrain-Wasser/See) + Angel-Spots (Resource-Pattern, `kind="fishing"`), Fische versch. Rarität (Forelle → goldener Fisch). Optional Mini-Spiel (Casten + Timing).
- 🟢 **Blumen/Kräuter sammeln** — die bereits platzierten Deko-Blumen zu **sammelbaren** Nodes machen (füttert Alchemie).
- 🟡 **Crafting-System** (`Config/Recipes`: Inputs → Output, Skill+Level, Station) — schaltet auf einen Schlag Dutzende Items frei:
  - **Schmieden:** Erz → Barren → Waffen/Rüstung (Tiers).
  - **Kochen:** roher Fisch/Fleisch → Essen (heilt).
  - **Herstellen:** Holz → Bretter → Werkzeuge/Möbel.
  - **Alchemie:** Kräuter → Tränke (Heilung, XP-Boost, Buffs).
- 🟡 **Werkzeug-Tiers** (Axt/Spitzhacke/Angel) — schneller/mehr Ausbeute, im Shop/craftbar.
- 🟡 **Gear-Tiers** (Waffen/Rüstung nach Material: Kupfer→Eisen→Mithril…).
- 🟢 **Item-Icons** statt Text-Kacheln (via `search_asset` Images oder generieren).

> **Beispiel wie billig das ist:** Fisch = 1 Zeile in `Items.ById` + Angel-Spot = 1 Eintrag in `Resources.Nodes` (kind="fishing") → fertig, inkl. Inventar, Drop, Highlight, Verkauf.

## 6. Was beim Skillen passiert (Progression-Effekte)
Aktuell: Schwert-Schaden skaliert bereits (`12 + floor(level*0.8)`). Sammeln hat Level-Gates. Sonst wenig spürbar.

**Empfehlung: zentrales `Config/Progression`- bzw. `Stats`-Modul**, das Skill-Level → Effekte mappt und von allen Systemen gelesen wird. Dann ist Balancing an einer Stelle.

- 🟢 **Combat-Schaden für alle** (Bogen/Magie wie Schwert) + **Max-HP** skaliert mit Kampf-Level.
- 🟢 **Sammel-Geschwindigkeit** — höheres Level = kürzere `HoldDuration` + Chance auf Extra-Ausbeute.
- 🟡 **Krit-Chance** steigt mit Combat-Level.
- 🟡 **Crafting** — höhere Erfolgs-/Qualitätschance, weniger Materialverlust mit Level.
- 🔴 **Meilenstein-Fähigkeiten** — alle 10 Level etwas freischalten (z. B. Schwert 10 = Wirbel-Angriff, Magie 15 = Feuerball).
- 🟡 **Gesamtlevel-Perks** — schaltet Dimensionen/Titel frei.

## 7. Was im Shop kaufen
Aktuell: Gold existiert, kein Shop. Skill „Handeln" definiert (inaktiv).

- 🟡 **Shop-System** — Händler-NPC im Dorf + Shop-UI (Kaufen/Verkaufen), `Config/Shop` mit Sortiment.
- Verkaufsware:
  - **Werkzeuge & Waffen/Rüstung** (Basis-Tiers).
  - **Verbrauchsgegenstände** — Heiltränke, Essen, XP-Booster, Teleport-Schriftrollen.
  - 🟢 **Inventar-Erweiterungen** (mehr Slots) — war explizit im Design!
  - **Angel-Köder/Vorräte.**
  - **Reittiere** (Design!) & **Pet-Zubehör**, Kosmetik.
  - **Bank/Lager-Zugang.**
- **Verkaufen:** Beute/Ressourcen zu Gold machen (Items haben schon `sell`-Preis).
- **Handeln-Skill:** bessere Preise mit Level; Spielerhandel (Design: nur ≤5 Level Differenz).
- **Wichtig als Gold-Senke** für eine gesunde Wirtschaft.

## 8. Bosskämpfe
Aktuell: keine Bosse. Design: 2 Bosse/Dimension; nächste Dimension wird per **Portal-Boss-Sieg** freigeschaltet — das ist die **Kern-Progression**.

- 🔴 **Boss-Framework** — MobSystem um Boss-Variante erweitern (`Config/Bosses`): mehr HP, **Phasen**, telegrafierte AoE-Angriffe (mit unserem Dodge-System ausweichbar!), Enrage-Timer, Add-Beschwörung.
- **Boss-Arena** + Beschwörung (Altar / nach Clearing / am Dimensionsende).
- 🟡 **Boss-Lebensbalken** (groß, oben).
- **Gruppen-Skalierung** (Design: bis 5 Spieler) — HP/Schaden nach Party-Größe.
- **Belohnung:** garantiert selten/episch, schaltet nächstes Portal frei.
- **Erster Boss: „Goblin-Häuptling"** (Flüsterwald) — großer Goblin mit Sturm-Angriff + Boden-Slam (AoE) + Goblin-Beschwörung.

## 9. Weitere Ideen
- 🔴 **Pets & Reittiere** (Design-Kern): Pet folgt + Buffs + Level; Mounts = Tempo.
- 🔴 **Dimension 2 (Gluthöhlen)** und weiter — skaliert über Config.
- 🟡 **Party/Gruppen-System** (Design: 5 Spieler), Party-UI, geteilte XP/Beute.
- 🟡 **Bank/Lager** (persistenter Stauraum, Design: Inventar-Erweiterungen).
- 🟡 **Tag/Nacht-Zyklus + Wetter** (beeinflusst Spawns/Stimmung).
- 🟡 **Achievements/Sammlungen/Titel**, Bestenlisten (Gesamtlevel).
- 🟢 **Onboarding/Tutorial** für neue Spieler.
- 🔴 **DataStore-Härtung** (ProfileService) + Anti-Exploit-Review vor Release (roblox-performance/security-Skills nutzen).
- 🟡 **Performance-Pass** für 100 Spieler (Drop-Pooling, Mob-KI-Throttling, StreamingEnabled-Tuning).

---

## Empfohlene Reihenfolge (Impact ÷ Aufwand)

1. **Sound- & Effekt-Pass** 🟢 — Kampf-/Sammel-/UI-SFX + Treffer-Partikel + Level-Up-Chime. Riesiger Immersions-Sprung für wenig Aufwand.
2. **Progression spürbar machen** 🟢🟡 — zentrales `Stats`-Modul: Combat-Schaden (alle), Max-HP, Sammel-Tempo, Krits.
3. **Crafting + Shop + Inventar-Slots** 🟡 — schließt den Kern-Loop (sammeln → craften → ausrüsten → verkaufen) und bringt viele Items.
4. **Erster Boss „Goblin-Häuptling" + Dimensions-Freischaltung** 🔴 — die eigentliche Fortschritts-Schleife.
5. **Angeln + Kräuter + weitere Skills aktivieren** 🟡 — Content-Breite.
6. **Pets/Reittiere, Dimension 2, Party** 🔴 — die großen Design-Ziele.
