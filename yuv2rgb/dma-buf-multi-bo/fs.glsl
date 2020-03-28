#extension GL_OES_EGL_image_external : require

precision mediump float;
uniform samplerExternalOES tex;
varying vec2 texcoord;

void main() {
    gl_FragColor = texture2D(tex, texcoord);
}
