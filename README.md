# n0130dy-crt2x

A CRT scanline shader for **Diablo II (Project Diablo 2 / D2GL)**, purpose-built for
**exact 2x integer scaling** — the one geometry where classic CRT presets break.
## Screenshots

**Before (plain upscale):**
<img width="2136" height="1200" alt="image" src="https://github.com/user-attachments/assets/09a74fe5-92c3-40aa-b408-ff073e8abfc0" />
**After (n0130dy-crt2x):**
<img width="2136" height="1200" alt="image" src="https://github.com/user-attachments/assets/28a5c6b1-faff-4fea-97e6-7b8c0f6ad6df" />

Diablo II with widescreen support renders internally at **1068x600**. Run it in a
**2136x1200 window** and every source pixel becomes a perfect 2x2 block: zero invented
pixels, zero upscaler mush. The catch: at exactly 2x, the symmetric beam profiles used
by stock CRT shaders sample at mirror-image phases on every line — both output rows get
identical brightness and **the scanlines cancel themselves into invisibility**. This
shader uses an asymmetric beam (lit row / dark row by construction), so the scanlines
survive integer scaling. That's the whole reason it exists.

Deliberately **single-pass**: sample, tone curve, scanline, mask, and color all run
per-pixel in one stage. Nothing to break, no measurable performance cost.

## Requirements

- Diablo II: LoD 1.13c via **D2GL** (tested on D2GL v1.3.3 / Project Diablo 2)
- A display of at least 2136x1200 (a 1440p monitor fits it windowed with room to spare)

## Install

1. Copy the `data` folder into your game folder (for PD2: `...\Diablo II\ProjectD2\`),
   so you end up with:
   ```
   ProjectD2\data\shaders\presets\n0130dy-crt2x.slangp
   ProjectD2\data\shaders\n0130dy\shaders\n0130dy-crt2x.slang
   ```
   Both files are required — the `.slangp` is the menu entry, the `.slang` is the code.
2. Add **`-direct`** to your launch arguments (launcher args field, or a shortcut to
   the game exe: `"...\Diablo II.exe" -3dfx -direct`).
3. In game, press **Ctrl+O**:
   - Screen tab → Window Size → **Custom 2136 x 1200**
   - Graphics tab → Upscale Shader Preset → **presets\n0130dy-crt2x.slangp** → Apply

## Recommended companion settings

- In-game **Gamma and Contrast sliders: dead center** (the shader's tone curve is
  calibrated for defaults — if the image looks wrong, check this first)
- D2GL **FXAA: OFF** (it blurs what the shader keeps sharp)
- D2GL **Luma Sharpen: ON** (default values are fine)
- Window size must be exactly **2x your internal resolution** (2136x1200 for 1068x600).
  Other sizes work but degrade the scanline regularity — that's physics, not a bug.

## Tuning

All knobs live at the top of `data\shaders\n0130dy\shaders\n0130dy-crt2x.slang` as
`#pragma parameter` lines. Edit the first number after the quoted text, save, and
re-Apply the preset in Ctrl+O (no relaunch needed).

| Parameter | Default | What it does |
|---|---|---|
| `SCANLINE_STRENGTH` | 0.55 | Darkness of the dark rows. 0 = scanlines off |
| `SCANLINE_PERIOD` | 1.5 | Line spacing: 1.0 fine, 1.5 classic, 2.0 chunky |
| `BEAM_SHAPE` | 2.5 | Hardness of the lit/dark falloff |
| `SOFTNESS` | 0.35 | 0 = raw pixels, 1 = full bilinear. "A little blob" |
| `MASK_STRENGTH` | 0.00 | Vertical RGB aperture-grille whisper. Try 0.05-0.10 |
| `BRIGHT_BOOST` | 1.20 | Pays back light the scanlines remove |
| `WARMTH` | 0.00 | Leans whites warm like an aging tube |
| `GAMMA` | 1.32 | Shadow depth. The dungeon-mood knob |
| `CONTRAST` | 1.08 | Gentle punch around mid-grey |
| `SATURATION` | 1.10 | Color richness |

## Troubleshooting

- **Preset not in the dropdown** → `-direct` flag missing, or the `data` folder landed
  one level too deep (`data\data\...`).
- **Preset listed but won't load / black screen** → the `n0130dy` code folder didn't
  come along, or the relative path inside the `.slangp` no longer matches.
- **Scanlines look uneven or faint** → window size isn't exactly 2x the internal
  resolution. Set 2136x1200.
- **Image too bright/dark** → in-game gamma/contrast sliders aren't centered.

## Credits

- [D2GL](https://github.com/bayaraa/d2gl) by Bayaraa — the wrapper that makes this possible
- The RetroArch/libretro slang shader format
- [ajtos/d2gl-custom-shader-presets](https://github.com/ajtos/d2gl-custom-shader-presets)
  for documenting D2GL's custom-preset loading
- Built and tuned by n0130dy

## License

MIT — see [LICENSE](LICENSE).
