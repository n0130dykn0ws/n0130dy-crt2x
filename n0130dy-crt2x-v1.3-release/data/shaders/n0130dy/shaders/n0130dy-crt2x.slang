#version 450

/*
   n0130dy-crt2x v1.3 -- designed for DEFAULT (centered) in-game gamma/contrast
   ------------------------------------------------------------
   by n0130dy -- CRT preset for Diablo II via D2GL,
   designed for EXACT 2x integer scale
   (1068x600 internal -> 2136x1200 window).

   Passes (all in one):
     1. Base sample: nearest-neighbor blended with a bilinear tap
        by SOFTNESS ("a little blob" control)
     2. Shadow depth (GAMMA): darkens shadows/mids, keeps
        highlights -- the dungeon mood knob
     3. Asymmetric scanline with adjustable SPACING:
          PERIOD 1.0 = fine line every source line  (2-row rhythm)
          PERIOD 1.5 = your old 1600x900 cadence    (3-row rhythm)
          PERIOD 2.0 = chunky retro block           (4-row rhythm)
     4. Optional phosphor mask whisper + warmth

   TUNING: edit the first number after the quoted text in the
   #pragma parameter lines, save, re-apply preset in Ctrl+O.
   ------------------------------------------------------------
*/

layout(push_constant) uniform Push
{
    vec4 SourceSize;
    vec4 OriginalSize;
    vec4 OutputSize;
    uint FrameCount;
    float SCANLINE_STRENGTH;
    float SCANLINE_PERIOD;
    float BEAM_SHAPE;
    float SOFTNESS;
    float MASK_STRENGTH;
    float BRIGHT_BOOST;
    float WARMTH;
    float GAMMA;
    float SATURATION;
    float CONTRAST;
} params;

// How dark the dark rows get. 0.0 = scanlines off, 1.0 = black lines.
#pragma parameter SCANLINE_STRENGTH "Scanline darkness" 0.55 0.0 1.0 0.05

// Scanline spacing: source lines per scanline cycle.
// 1.0 = fine, 1.5 = old 1600x900 rhythm, 2.0 = chunky.
#pragma parameter SCANLINE_PERIOD "Scanline spacing" 1.5 1.0 3.0 0.5

// Shape of the lit/dark falloff. Higher = harder, crisper lines.
#pragma parameter BEAM_SHAPE "Beam hardness" 2.5 0.5 6.0 0.1

// "A little blob": 0.0 = pure nearest-neighbor pixels,
// 1.0 = full bilinear smoothing. Try 0.2-0.35.
#pragma parameter SOFTNESS "Pixel blend (little blob)" 0.35 0.0 1.0 0.05

// Vertical RGB stripe (aperture grille whisper). 0.0 = off.
#pragma parameter MASK_STRENGTH "Phosphor mask whisper" 0.00 0.0 0.5 0.01

// Compensates brightness lost to scanlines/mask if needed.
#pragma parameter BRIGHT_BOOST "Brightness compensation" 1.20 1.0 1.5 0.01

// Leans whites slightly warm like an aging tube. 0.0 = untouched.
#pragma parameter WARMTH "CRT warmth" 0.0 0.0 0.3 0.01

// Shadow depth / contrast. 1.0 = untouched. Higher = darker
// shadows & mids while highlights stay put.
#pragma parameter GAMMA "Shadow depth" 1.32 0.8 1.6 0.01

// Contrast around the midpoint. 1.0 = untouched, ~1.06 = gentle punch.
#pragma parameter CONTRAST "Contrast" 1.08 0.7 1.5 0.01

// Color pop. 1.0 = untouched, ~1.10 = a little richer.
#pragma parameter SATURATION "Saturation" 1.10 0.5 1.5 0.01

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
    // --- 1. Base sample: NN blended with bilinear by SOFTNESS ---
    vec2 srcPix  = vTexCoord * params.SourceSize.xy;
    vec2 snapped = (floor(srcPix) + 0.5) * params.SourceSize.zw;
    vec3 nn      = texture(Source, snapped).rgb;    // exact texel (linear filter at center = raw value)
    vec3 bl      = texture(Source, vTexCoord).rgb;  // true bilinear tap
    vec3 col     = mix(nn, bl, params.SOFTNESS);

    // --- 2. Shadow depth ---
    col = pow(col, vec3(params.GAMMA));

    // --- 3. Asymmetric scanline with spacing ---
    // phase = position within the current scanline cycle (0..1).
    // Beam centered at 0.25 => asymmetric; cannot phase-cancel at 2x.
    float phase = fract(srcPix.y / params.SCANLINE_PERIOD);
    float w     = 0.5 + 0.5 * cos(6.28318530718 * (phase - 0.25));
    w           = pow(w, params.BEAM_SHAPE);
    float scan  = mix(1.0 - params.SCANLINE_STRENGTH, 1.0, w);

    // --- 4. Whisper of aperture mask (vertical RGB stripe) ---
    float opx  = mod(floor(vTexCoord.x * params.OutputSize.x), 3.0);
    vec3  mask = vec3(1.0 - params.MASK_STRENGTH);
    if      (opx < 0.5) mask.r = 1.0;
    else if (opx < 1.5) mask.g = 1.0;
    else                mask.b = 1.0;

    col *= scan;
    col *= mask;
    col *= params.BRIGHT_BOOST;

    // --- 4b. Contrast (pivot at mid-grey) ---
    col = clamp(mix(vec3(0.5), col, params.CONTRAST), 0.0, 1.0);

    // --- 5. Color pop ---
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, params.SATURATION);

    // --- 6. Warmth ---
    col = mix(col, col * vec3(1.05, 1.00, 0.92), params.WARMTH);

    FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
