var shell = require("gl-now")()
var createFBO = require("gl-fbo") // render to texture
var glShader = require("gl-shader")
var glslify = require("glslify")
var ndarray = require("ndarray")
var fill = require("ndarray-fill")
var fillScreen = require("a-big-triangle") // bb
var createTexture = require("gl-texture2d")

var ratio

var blurFbo, blurProg,
sharpFbo, sharpProg,
passThruProg

var params = {
    blurWidth: 0.6,
    blurAmp: 16.0,
    sharpWidth: 1.0,
    sharpAmp: 9.5,
    scaleCoef: -0.001,
    reset: 20,
}

function seed(fbo) {
    var w = fbo._shape[0]
    var h = fbo._shape[1]
    var initial_conditions = ndarray(new Uint8Array(w * h * 4), [w, h, 4])
    fill(initial_conditions, function(x, y, c) { // seed
        if (c == 3) {
            return 255; // alpha channel
        }
        return Math.random() * 255
    })
    fbo.color[0].setPixels(initial_conditions) // write seed to one fbo
}

global.params = params // for js console tweaking
global.shell = shell

shell.on("gl-init", function() {
    var gl = shell.gl
    var canvas = shell.canvas

    ratio = window.devicePixelRatio ? window.devicePixelRatio : 1;
    // var ratio = 1;
    canvas.width = canvas.clientWidth * ratio;
    canvas.height = canvas.clientHeight * ratio;

    // shell.scale = 1 / ratio;

    var w = shell.width * ratio
    var h = shell.height * ratio
    var size = [w, h];

    // enable openGL's blending for alpha to work
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.enable(gl.BLEND);

    var passthru_vs = glslify("./passthru.vs.glsl")
    passThruProg = glShader(gl, passthru_vs, glslify("./draw.fs.glsl"))
    sharpProg = glShader(gl, passthru_vs, glslify("./sharp.glsl"))
    blurProg = glShader(gl, passthru_vs, glslify("./blur.glsl"))

    blurFbo = createFBO(gl, size)
    sharpFbo = createFBO(gl, size)

    seed(sharpFbo);
})

shell.on("gl-render", function(t) {
    var gl = shell.gl

    blurFbo.bind()
    blurProg.bind()
    blurProg.uniforms.buffer = sharpFbo.color[0].bind()
    blurProg.uniforms.dims = sharpFbo.shape
    blurProg.uniforms.width = params.blurWidth
    blurProg.uniforms.amp = params.blurAmp
    blurProg.uniforms.scaleCoef = params.scaleCoef //  * (shell.mouseX/shell.width)
    fillScreen(gl)

    sharpFbo.bind()
    sharpProg.bind()
    sharpProg.uniforms.buffer = blurFbo.color[0].bind()
    sharpProg.uniforms.dims = blurFbo.shape
    sharpProg.uniforms.width = params.sharpWidth
    sharpProg.uniforms.amp = params.sharpAmp
    sharpProg.uniforms.mouse = [(shell.mouseX / shell.width) * 0.25, (shell.mouseY / shell.height) * 0.25]
    sharpProg.uniforms.t = t
    fillScreen(gl)

    // draw blur fbo contents to screen
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    passThruProg.bind()
    passThruProg.uniforms.buffer = blurFbo.color[0].bind()
    fillScreen(gl)
})

shell.on("gl-resize", function(w, h) {
    shell.canvas.width = shell.canvas.clientWidth * ratio;
    shell.canvas.height = shell.canvas.clientHeight * ratio;
    shell.gl.viewport(0, 0, w, h)
    console.log(w, h);
})