
uniform vec4 count;
uniform float count1;
uniform float count2;

void main() {

     float i,j;
     float v = 0.0;

     for (i = 1.0; i < count.x; i+=1.0) {
     	 for (j = 1.0; j < count.y; j+=1.0)
     	     v += count2 + count1;
	 //v += 0.1;
     }
     
     gl_FragColor = vec4(1.0, v, 0.0, 1);
}
