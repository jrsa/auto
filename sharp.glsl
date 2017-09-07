precision mediump float;

uniform sampler2D shampler;
uniform vec2 dims;

uniform float width, amp;

uniform vec2 mouse;

varying vec2 uv;

//
//  HSV FUNCTIONS
//
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 color) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(color.xxx + K.xyz) * 6.0 - K.www);
    vec3 rgb = vec3(color.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), color.y));

    return rgb;
}

//
//  MAIN
//
void main() {
    // copy this so that we can modify it :x
    vec2 tc = uv;

    // previous shaders used the vertex position instead of UV, which
    // also required a "halving" transformation which is omitted here
    //vec4 pos = vec4(uv.s, uv.t, 0.0, 1.0); // previous shaders used the vertex position instead of UV
    // vec3 pixel = texture2D(shampler, tc).rgb;

    // output
    vec4 color = vec4(0.0);

    // constant zoom/rotate
    float scalex = 0.995 + (0.01 * mouse.x);
    float scaley = 0.995 + (0.01 * mouse.y);

    float fixangle = 0.001;
    tc -= vec2(0.5);
    tc *= mat2(scalex, 0.0, 0.0, scaley);
    tc *= mat2(cos(fixangle), sin(fixangle), -sin(fixangle), cos(fixangle));
    tc += vec2(0.5);

    // zoom/rotate based on hue/saturation
    vec3 pixel = texture2D(shampler, tc).rgb;
    vec3 s = rgb2hsv(pixel);

    float angle = ((tc.s + 0.4) * 0.04) * ((s.r * s.g) - 0.5);
    angle *= 0.275;

    tc -= vec2(0.5);
    tc *= mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    tc += vec2(0.5);

    float xscale = 1. - (-s.r * 0.009);
    float yscale = 1. - (s.g * 0.009);

    tc -= vec2(0.5);
    tc *= mat2(xscale, 0., 0., yscale);
    tc += vec2(0.5);

    // these aren't too different...
    float d = dot(s.bg, tc);
    float e = dot(s.rb, tc.ts);
    // d = length(s.bg);
    // d = 1.0;

    // get a neighboring pixel based on the above value
    vec4 prelook = texture2D(shampler, tc + (d * 0.3));

    // don't look at me, idk man
    d *= prelook.b;
    d += length(prelook) / 4.0;
    d -= length(s) / 4.0;

    // final texture sample
    vec4 bc_out = texture2D(shampler, tc + (d * 0.001)) * ((d * 0.001) + 1.0);

    // shift hue and saturation
    vec3 shift = s;
    shift.r += (d / 10.0);
    shift.g += (d * 0.08);

    // mix between the shifted and repositioned values
    float q = 40.0 * (-s.g);
    color += mix(bc_out, vec4(hsv2rgb(shift), 1.0), mouse.x);

    // spatial differencing using intermediate pixel value (`prelook`)
    color += 0.005;
    // color *= 1.005;
    color *= .99 + (e * .015);
    color -= (prelook * 0.02);
    gl_FragColor = color;
}