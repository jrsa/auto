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
    vec4 pos = vec4(uv.s, uv.t, 0.0, 1.0); // previous shaders used the vertex position instead of UV
    vec3 pixel = texture2D(shampler, tc).rgb;

    vec3 hsv = rgb2hsv(pixel);

    mat2 sca = mat2(1. + hsv.r, 0., 0., 1. + hsv.r);

    float angle = 0.05 * hsv.r;
    mat2 rot = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));

    // size of one pixel (filter width scales by this so that )
    vec2 offs = vec2(1. / dims.x, 1. / dims.y);

    tc *= sca;
    tc *= rot;

    vec2 src = tc;

    offs *= mat2(cos(angle), sin(width), -sin(width), cos(angle));
    float width = width + hsv.g;    

    vec2 tc4 = src;
    vec2 tc1 = src + vec2(0.0, -offs.t * width);
    vec2 tc3 = src + vec2(-offs.s * width, 0.0);
    vec2 tc5 = src + vec2(offs.s * width, 0.0);
    vec2 tc7 = src + vec2(0.0, offs.t * width);

    vec4 col1 = texture2D(shampler, tc1);
    vec4 col3 = texture2D(shampler, tc3);
    vec4 col5 = texture2D(shampler, tc5);
    vec4 col7 = texture2D(shampler, tc7);

    //
    //  HUE SHIFT
    //
    hsv.b -= 0.0169;

    vec2 pos_factor = (pos.xy * mouse);
    pos_factor *= mat2(0.5, 0.0, 0.0, 0.5);
    pos_factor *= rot;

    float d = dot(vec4(pos_factor, pos.zw), vec4(hsv, 0.23));
    d *= dot(vec4(pos_factor, pos.zw), vec4(hsv * 3.50, 1.0));
    d *= 1.2;

    // hsv.r += (d * 0.04);
    // hsv.r -= (d * mouse.x * 0.05);

    float amp = 19.0;
    gl_FragColor = vec4(hsv2rgb(hsv), 1.0) * (d * 4.5) - ((col1 + col3 + col5 + col7) / amp);
}
