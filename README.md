# Talentum Nap – live game voting

Kids vote on their phones, the winners appear live in a Godot game on stage, and after each stage every kid unlocks *their own* pick in their own copy of the game with a secret code.

| Page | Who | What |
|---|---|---|
| `index.html` | kids' phones | vote, see live results, get the secret code for their pick |
| `show.html` | projector | live bars, QR code, winner highlight, features built so far |
| `admin.html` | host | start / lock rounds, pick winner, switch to try-out mode, reset |
| `godot/Unlocks.gd` + `code_box.gd` | kids' game | code box; each code unlocks one feature |
| `godot/VoteBridge.gd` | stage game | listens to the votes live |

Rounds, images, **secret codes** and the game URL are configured in `js/shared.js` (`ROUNDS`, `GAME_URL`).
`CODES` in `godot/Unlocks.gd` and `ROUND_SIZES` in `godot/VoteBridge.gd` must match.

## Database

```
currentGroup : 0..3              active round
options/<i>  : { text, votes }   all options, rounds back-to-back (3+3+2+3)
locked/<r>   : true              round closed, no more votes
winners/<r>  : 0..n-1            winning option *inside* round r  ← Godot reacts to this
phase        : "vote" | "play"   "play" = phones show the code for the current round
resetFlag    : timestamp         changes on reset → phones forget their votes
```

Firebase rules must let the admin write `locked`, `winners`, `phase`, `resetFlag`, and let everyone read them
(the game reads the whole database via REST: `GET <db>/.json`).

## Show flow (per stage)

1. Admin presses **Indítás** on round r → phones show the options (`phase` goes back to `"vote"`).
2. Kids vote; the projector updates live.
3. Admin presses **Lezárás** (or **Ez nyer** to pick by hand, e.g. on a tie) → the stage game swaps in the winner.
4. You show the development on stage.
5. Admin presses **Kipróbálás** → every phone shows **one code: the one for the option that kid chose in round r**.
   Kids who didn't vote get the stage winner's code.
6. Kids type the code into the code box in their game → that feature unlocks (and is saved).
7. Next stage: back to 1. After stage 2 they have 2 features, and so on.

Codes per option (also listed on each round card in the admin page):

| Round | Options → codes |
|---|---|
| Hős | Kalandor `4821` · Dínó `1937` · Árny `6054` |
| Ellenfél | Vaddisznó `2768` · Nyuszi `9310` · Kísértet `5142` |
| Pálya | Szakadék `7493` · Erdő `3086` |
| Képesség | Repülés `8615` · Mesterlövész `0279` · Szupergyorsaság `6831` |

The codes are in the page source, so a determined kid could find them – fine for this event.

## Connecting Godot

All variants are built into the game beforehand; codes and votes only *select* which one is active
(see `godot/example_game.gd`).

- **Kids' game:** add `Unlocks.gd` as an autoload named `Unlocks`, and put a code box scene
  (Control + `LineEdit "Code"`, `Button "Unlock"`, `Label "Feedback"`, script `code_box.gd`) on screen.
  `Unlocks.try_code("1937")` unlocks, emits `feature_unlocked(stage, option)` and saves to `user://unlocks.cfg`
  (on a web export this survives page reloads). `Unlocks.clear()` resets it for the next kid on a shared computer.
  No internet needed.
- **Stage game:** set `stage_mode = true` on the example scene. It calls `VoteBridge.start_live()`, which polls
  Firebase every 0.5 s and emits `round_changed`, `votes_changed`, `winner_chosen`, `phase_changed`.
- **Web export for phones:** export to Web, put it in this repo (e.g. `game/`) and set `GAME_URL = "game/index.html"`
  in `js/shared.js` → phones get a **Játék megnyitása** button next to their code.
  (In Godot 4.3+ untick *Thread Support* in the Web export so it runs on GitHub Pages.)

More ideas:
- Use `votes_changed` during voting to tease on stage: the leading option bounces/glows in the game.
- Play a sparkle + sound when `feature_unlocked` / `winner_chosen` fires so the change feels like a reward.
