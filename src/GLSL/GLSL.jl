## Not julia code just for reference ##




#ifdef GL_ES
precision highp float;
precision mediump float;
precision lowp float;
#endif


vec4 red(){
    return vec4(1.0,0.0,0.0,1.0);
}


void main() {
	gl_FragColor = vec4(1.0,0.0,1.0,0.3);
  # Integer may fail to be converted to float automatically
  gl_FragColor = vec4(1,0,0,1);    // This kind of code will NOT always work

  gl_FragColor = red()
}







