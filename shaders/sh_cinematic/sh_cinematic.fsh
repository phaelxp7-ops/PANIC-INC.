// Second post-process pass: bloom composite, ACES tonemap and restrained horror grade.
precision highp float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform sampler2D u_bloom;
uniform vec2 u_resolution;
uniform float u_sanity;
uniform float u_panic;
uniform float u_hurt;
uniform float u_biome;
uniform float u_quality;
uniform float u_time;
vec3 aces(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}
void main() {
    vec2 uv = v_vTexcoord;
    vec2 centered = uv - 0.5;
    float fear = clamp((1.0 - u_sanity) * 0.75 + u_panic * 0.5, 0.0, 1.0);
    uv.x += fear * 0.0025 * sin(uv.y * 34.0 + u_time * 3.0);
    float edge = smoothstep(0.1, 0.72, length(centered));
    float ca = (0.0008 + fear * 0.003) * edge;
    vec3 col;
    col.r = texture2D(gm_BaseTexture, uv + vec2(ca, 0.0)).r;
    col.g = texture2D(gm_BaseTexture, uv).g;
    col.b = texture2D(gm_BaseTexture, uv - vec2(ca, 0.0)).b;
    vec3 bloom = texture2D(u_bloom, v_vTexcoord).rgb;
    if (u_quality > 1.5) {
        vec2 px = 1.0 / max(u_resolution, vec2(1.0));
        bloom += texture2D(u_bloom, v_vTexcoord + vec2(px.x, 0.0)).rgb;
        bloom += texture2D(u_bloom, v_vTexcoord - vec2(px.x, 0.0)).rgb;
        bloom += texture2D(u_bloom, v_vTexcoord + vec2(0.0, px.y)).rgb;
        bloom += texture2D(u_bloom, v_vTexcoord - vec2(0.0, px.y)).rgb;
        bloom *= 0.2;
    }
    col += bloom * (u_quality < 0.5 ? 0.0 : 0.28);
    vec3 grade = vec3(1.0);
    if (u_biome < 0.5) grade = vec3(0.82, 1.02, 0.92);
    else if (u_biome < 1.5) grade = vec3(1.08, 0.96, 0.78);
    else if (u_biome < 2.5) grade = vec3(0.78, 0.94, 1.10);
    else grade = vec3(1.12, 0.78, 0.84);
    col *= grade;
    col = mix(vec3(dot(col, vec3(0.299, 0.587, 0.114))), col, 0.88 + u_sanity * 0.12);
    col = aces(col * (1.0 + u_hurt * 0.14));
    float vignette = 1.0 - smoothstep(0.18, 0.76, length(centered)) * (0.18 + fear * 0.32);
    col *= vignette;
    float grain = fract(sin(dot(v_vTexcoord * u_resolution + u_time, vec2(12.9898, 78.233))) * 43758.5453);
    col += (grain - 0.5) * (0.012 + fear * 0.022);
    col = mix(col, vec3(col.r * 1.12, col.g * 0.45, col.b * 0.5), u_hurt * 0.18);
    gl_FragColor = vec4(col, 1.0) * v_vColour;
}
