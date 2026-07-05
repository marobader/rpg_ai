# Fantasy Skill-RPG — Game Design Document

*Status: Design v0.1 — Stand 2026-07-05*

Ein Roblox-RPG im RuneScape-Stil: Spieler leveln einzelne Skills in einer Fantasy-Welt,
kämpfen gegen Mobs, sammeln/craften Items, erledigen Quests und reisen durch Dimensionen.

---

## 1. Skill-System (Kern)

Jeder Skill levelt **einzeln** (1–50). Zusätzlich gibt es ein **Gesamt-Charakterlevel**
(abgeleitet aus der Summe/Kombination aller Skill-Level).

**12 Skills in 4 Kategorien:**

| Kategorie   | Skills                        |
|-------------|-------------------------------|
| Kampf       | Schwert, Bogen, Magie         |
| Sammeln     | Holzfällen, Bergbau, Angeln   |
| Handwerk    | Schmieden, Kochen, Herstellen |
| Wissen      | Alchemie, Handeln, Archäologie|

- **Max-Level pro Skill:** 50
- Skills schalten sich **nicht gegenseitig** frei, ABER Aktionen/Rezepte haben
  Level-Anforderungen (z. B. Eisen abbauen ab Bergbau X, Eisenschwert schmieden ab Schmieden Y).
- **Pets:** besitzbar, haben eigene Level.
- **Reittiere (Mounts):** besitzbar.

## 2. Kampf & Mobs

- **Echtzeit-Kampf:** anvisieren/anklicken, zuschlagen, **Ausweichen** (Dodge).
- Mobs sind nach **Dimension** organisiert: pro Dimension **3–5 neue Mob-Typen + 2 Bosse**.
- Mob-Design folgt pro Dimension (nächster Schritt).

## 3. Welt & Fortschritt

- **Heimatbereich:** ein Dorf (Hub mit NPCs, Shops, Portalen).
- **5 Dimensionen** zum Start, jede = eine Zone, erreichbar per **Portal/Teleport**.
- **Fortschritt:** Nächste Dimension wird durch Besiegen des **Dimensionsportal-Bosses** freigeschaltet.

## 4. Items & Wirtschaft

- **Item-Typen:** Waffen, Rüstung, Verbrauchsgegenstände (Tränke), Ressourcen (Erz, Holz), Quest-Items.
- **Inventar:** begrenzter Platz; **Erweiterungen** kaufbar / findbar / schmiedbar.
- **Währung:** Gold. Shops/Händler-NPCs.
- **Spielerhandel:** nur zwischen Spielern, deren Level **≤ 5 auseinander** liegt.
- **Raritäten:** gewöhnlich / selten / episch / mystisch.

## 5. Quests & NPCs

- **Quest-Arten:** Story-Quests, „Töte X Mobs", „Sammle X Items", „Bring X zu NPC Y",
  „Kartographiere Gegend", „Finde NPC" …
- **NPCs:** einfache Dialoge mit Auswahlmöglichkeiten.
- Vorerst **keine übergeordnete Story** — lose Quests zum Leveln.

## 6. Multiplayer & Speichern

- **100 Spieler** pro Server.
- **Gruppen bis 5 Spieler** (gemeinsames Kämpfen).
- **Persistenz:** dauerhaft via **DataStore**.

## 7. Umfang & Stil

- **Prototyp-Ziel (MVP):** 1 Dimension, **3 Skills + 3 Mobs + 1 Quest**, spielbar.
- **Grafikstil:** eigener Stil, **mid-poly** (nicht flat-low-poly, nicht ultra-detailliert).
- **Immersion:** atmosphärische Effekte, Umgebungsgeräusche, Sounds, Partikel.

---

## Offene Design-Entscheidungen

- XP-Kurve pro Skill (linear vs. exponentiell) und Formel fürs Gesamt-Charakterlevel.
- Auswahl der 3 Prototyp-Skills + Prototyp-Dimension.
- Konkrete 5 Dimensionen (Themen, Level-Bereiche, Mobs, Bosse, Ressourcen).
