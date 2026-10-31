// First post-process pass: extract bright pixels and soften the glow.
precision highp float;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 u_resolution;
uniform float u_threshold;
void main() {
    vec2 px = 1.0 / max(u_resolution, vec2(1.0));
    vec3 c = texture2D(gm_BaseTexture, v_vTexcoord).rgb * 0.4;
    c += texture2D(gm_BaseTexture, v_vTexcoord + vec2(px.x * 2.0, 0.0)).rgb * 0.15;
    c += texture2D(gm_BaseTexture, v_vTexcoord - vec2(px.x * 2.0, 0.0)).rgb * 0.15;
    c += texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, px.y * 2.0)).rgb * 0.15;
    c += texture2D(gm_BaseTexture, v_vTexcoord - vec2(0.0, px.y * 2.0)).rgb * 0.15;
    float brightness = max(max(c.r, c.g), c.b);
    vec3 glow = c * max(brightness - u_threshold, 0.0) / max(brightness, 0.001);
    gl_FragColor = vec4(glow, 1.0) * v_vColour;
}
