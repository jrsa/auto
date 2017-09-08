var shell = require("gl-now")()
var createFBO = require("gl-fbo") // render to texture
var glShader = require("gl-shader")
var glslify = require("glslify")
var fillScreen = require("a-big-triangle") // bb
var createTexture = require("gl-texture2d")

var ratio

var blurFbo, blurProg,
feedbackFbo, sharpProg,
passThruProg

shell.on("gl-init", function() {
    var gl = shell.gl
    var canvas = shell.canvas

    ratio = window.devicePixelRatio ? window.devicePixelRatio : 1;

    canvas.width = canvas.clientWidth * ratio;
    canvas.height = canvas.clientHeight * ratio;

    var w = shell.width * ratio
    var h = shell.height * ratio
    var size = [w, h];

    var passthru_vs = glslify("./passthru.vs.glsl")
    passThruProg = glShader(gl, passthru_vs, glslify("./draw.fs.glsl"))
    sharpProg = glShader(gl, passthru_vs, glslify("./sharp.glsl"))
    blurProg = glShader(gl, passthru_vs, glslify("./blur.glsl"))

    blurFbo = createFBO(gl, size)
    feedbackFbo = createFBO(gl, size)
})

shell.on("gl-render", function(t) {
    var gl = shell.gl

    // draw contents of feedbackFbo into blurFbo, using blur shader
    blurFbo.bind()
    blurProg.bind()
    blurProg.uniforms.buffer = feedbackFbo.color[0].bind()
    blurProg.uniforms.dims = feedbackFbo.shape
    fillScreen(gl)

    // inverse of the above, draw blurFbo contents into feedbackFbo using goopy feedback shader
    feedbackFbo.bind()
    sharpProg.bind()
    sharpProg.uniforms.buffer = blurFbo.color[0].bind()
    sharpProg.uniforms.dims = blurFbo.shape
    sharpProg.uniforms.mouse = [(shell.mouseX / shell.width) * 0.25, (shell.mouseY / shell.height) * 0.25]
    fillScreen(gl)

    // draw contents of blurFbo to screen
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    passThruProg.bind()
    passThruProg.uniforms.buffer = blurFbo.color[0].bind()
    fillScreen(gl)
})

shell.on("gl-resize", function(w, h) {
    shell.canvas.width = shell.canvas.clientWidth * ratio;
    shell.canvas.height = shell.canvas.clientHeight * ratio;
    shell.gl.viewport(0, 0, w, h)
})