precision mediump float;

uniform vec4 u0;
uniform vec4 u1;
uniform vec4 u2;
uniform vec4 u3;
uniform vec4 u4;
uniform vec4 u5;
uniform vec4 u6;
uniform vec4 u7;
uniform vec4 u8;
uniform vec4 u9;

uniform vec4 v0;

void main() {
     vec4 t0 = v0 + u0;
     vec4 t1 = v0 + u1;
     vec4 t2 = v0 + u2;
     vec4 t3 = v0 + u3;
     vec4 t4 = v0 + u4;
     vec4 t5 = v0 + u5;
     vec4 t6 = v0 + u6;
     vec4 t7 = v0 + u7;
     vec4 t8 = v0 + u8;
     vec4 t9 = v0 + u9;

     vec4 t1000 = t0 + t0;
     vec4 t1001 = t0 + t1;
     vec4 t1002 = t0 + t2;
     vec4 t1003 = t0 + t3;
     vec4 t1004 = t0 + t4;
     vec4 t1005 = t0 + t5;
     vec4 t1006 = t0 + t6;
     vec4 t1007 = t0 + t7;
     vec4 t1008 = t0 + t8;
     vec4 t1009 = t0 + t9;

     vec4 t1010 = t1000 + t0;
     vec4 t1011 = t1000 + t1;
     vec4 t1012 = t1000 + t2;
     vec4 t1013 = t1000 + t3;
     vec4 t1014 = t1000 + t4;
     vec4 t1015 = t1000 + t5;
     vec4 t1016 = t1000 + t6;
     vec4 t1017 = t1000 + t7;
     vec4 t1018 = t1000 + t8;
     vec4 t1019 = t1000 + t9;

     gl_FragColor =
       t1010 + t1011 + t1012 + t1013 + t1014 +
       t1015 + t1016 +
       t1017 + t1018 + t1019 +
       t1000 + t1001 + t1002 + t1003 + t1004 +
       t1005 + t1006 +
       t1007 + t1008 + t1009 +
       t0 + t1 + t2 + t3 + t4 +
       t5 + t6 +
       t7 + t8 + t9 +
       u0 + u1 + u2 + u3 + u4 +
       u5 + u6 +
       u7 + u8 + u9 +
       v0;
}
