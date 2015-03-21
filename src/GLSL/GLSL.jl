## Not julia code just for reference ##
# I will promote these code to executable JuliaGL code in the future.

# Set up precision #

#ifdef GL_ES
precision highp float;
precision mediump float;
precision lowp float;
#endif

# Set up uniform #
uniform vec2 u_resolution; // Canvas size (width,height)
uniform vec2 u_mouse;      // mouse position in screen pixels
uniform float u_time;      // Time in seconds since load
uniform vec3 iResolution;   // viewport resolution (in pixels)
uniform vec4 iMouse;        // mouse pixel coords. xy: current, zw: click
uniform float iGlobalTime;  // shader playback time (in seconds)
uniform mat2 example1;
uniform mat3 example2;
uniform mat4 example3;
uniform sampler2D example4;
uniform samplerCube example5;




# Set up function #
vec4 red(){
    return vec4(1.0,0.0,0.0,1.0);
}


void main() {
	gl_FragColor = vec4(1.0,0.0,1.0,0.3);
  # Integer may fail to be converted to float automatically
  gl_FragColor = vec4(1,0,0,1);    // This kind of code will NOT always work

  gl_FragColor = red()
}









## smoothstep & step ##

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

// Plot a line on Y using a value between 0.0-1.0
float plot(vec2 st, float pct){
  return  smoothstep( pct-0.02, pct, st.y) -
          smoothstep( pct, pct+0.02, st.y);
}

void main() {
	vec2 st = gl_FragCoord.xy/u_resolution;

    float y = st.x;

    vec3 color = vec3(y);

    // Plot a line
    float pct = plot(st,y);
    color = (1.0-pct)*color+pct*vec3(0.0,1.0,0.0);

	gl_FragColor = vec4(color,1.0);
}



## useful functions ##

y = mod(x,0.5); // return x modulo of 0.5
y = fract(x); // return only the fraction part of a number
y = ceil(x);  // nearest integer that is greater than or equal to x
y = floor(x); // nearest integer less than or equal to x
y = sign(x);  // extract the sign of x
y = abs(x);   // return the absolute value of x
y = clamp(x,0.0,1.0); // constrain x to lie between 0.0 and 1.0
y = min(0.0,x);   // return the lesser of x and 0.0
y = max(1.0,x);   // return the greater of x and 1.0


