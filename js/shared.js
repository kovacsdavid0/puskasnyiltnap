import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getDatabase } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-database.js";

const firebaseConfig = {
    apiKey: "AIzaSyDmb4zgzbOlF_8KtjwaCJn3y_2DwYapqQk",
    authDomain: "talentum-nap.firebaseapp.com",
    databaseURL: "https://talentum-nap-default-rtdb.europe-west1.firebasedatabase.app",
    projectId: "talentum-nap",
    storageBucket: "talentum-nap.firebasestorage.app",
    messagingSenderId: "930243290620",
    appId: "1:930243290620:web:4ce6c75911ecd13ba4be79",
};

export const app = initializeApp(firebaseConfig);
export const db = getDatabase(app);

/* ===============================
   ROUNDS
   Each round = one thing the game will get.
   Option texts come from Firebase (options/<i>/text), `names` is only a fallback.
   `codes` = secret unlock code per option, typed into the Godot game.
   KEEP IN SYNC with CODES in godot/Unlocks.gd.
   =============================== */
export const ROUNDS = [
    {
        key: "hero",
        label: "Hős",
        prompt: "Ki legyen a hős?",
        images: ["assets/adventure.png", "assets/dino.png", "assets/shadow.png"],
        names: ["Kalandor", "Dínó", "Árny"],
        codes: ["4821", "1937", "6054"],
    },
    {
        key: "enemy",
        label: "Ellenfél",
        prompt: "Ki legyen az ellenfél?",
        images: ["assets/boar.png", "assets/bunny.png", "assets/template.png"],
        names: ["Vaddisznó", "Nyuszi", "Kísértet"],
        codes: ["2768", "9310", "5142"],
    },
    {
        key: "world",
        label: "Pálya",
        prompt: "Hol játszódjon?",
        images: ["assets/abyss.png", "assets/forest.png"],
        names: ["Szakadék", "Erdő"],
        codes: ["7493", "3086"],
    },
    {
        key: "power",
        label: "Képesség",
        prompt: "Milyen szupererőt kapjon?",
        images: ["assets/fly.png", "assets/sniper.png", "assets/speeed.png"],
        names: ["Repülés", "Mesterlövész", "Szupergyorsaság"],
        codes: ["8615", "0279", "6831"],
    },
];

/* Link to the web export of the game, shown next to the unlock code.
   Leave empty to hide the button. */
export const GAME_URL = "";

/* Address printed under the QR code on the projector. */
export const VOTE_URL_LABEL = location.host + location.pathname.replace(/[^/]*$/, "");

export function roundRange(round) {
    let start = 0;
    for (let i = 0; i < round; i++) start += ROUNDS[i].images.length;
    return { start, end: start + ROUNDS[round].images.length };
}

export const TOTAL_OPTIONS = ROUNDS.reduce((n, r) => n + r.images.length, 0);

/* Returns [{ text, votes, img }] for the options of one round. */
export function roundOptions(options, round) {
    const { start, end } = roundRange(round);
    const list = [];
    for (let i = start; i < end; i++) {
        const local = i - start;
        const opt = options?.[i] ?? {};
        list.push({
            text: opt.text || ROUNDS[round].names[local] || `Opció ${local + 1}`,
            votes: opt.votes || 0,
            img: ROUNDS[round].images[local],
        });
    }
    return list;
}

/* Index of the option with the most votes (first one wins a tie), or -1 with no votes. */
export function leaderIndex(list) {
    let best = -1;
    let max = 0;
    list.forEach((o, i) => {
        if (o.votes > max) { max = o.votes; best = i; }
    });
    return best;
}

/* Tiny sprites look blurry when scaled up – switch them to crisp pixels. */
export function crispIfSmall(img) {
    const apply = () => { if (img.naturalWidth && img.naturalWidth < 200) img.classList.add("pixel"); };
    img.complete ? apply() : img.addEventListener("load", apply, { once: true });
}

/* The unlock code a kid gets for one round:
   their own pick, otherwise the stage winner, otherwise the current leader.
   Returns { option, code, fromWinner } or null when nobody voted yet. */
export function stageCode(round, picks, winners, options) {
    let option = picks?.[round];
    const fromWinner = option === undefined;
    if (fromWinner) option = winners?.[round] ?? leaderIndex(roundOptions(options, round));
    if (option == null || option < 0) return null;
    return { option, code: ROUNDS[round].codes[option], fromWinner };
}

export function clampRound(value) {
    const n = Number(value) || 0;
    return Math.min(Math.max(n, 0), ROUNDS.length - 1);
}
