attribute vec3 positionIn;
attribute vec4 colorIn;

varying vec2 color;
//varying vec3 color2;

void main()
{
    color = colorIn.rg;
    //color2 = colorIn.rgb;
    gl_Position = vec4(positionIn, 1);
}
