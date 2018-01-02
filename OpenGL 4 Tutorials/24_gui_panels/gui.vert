#version 410

in vec2 vp;

uniform vec2 gui_scale;

out vec2 st;

void main() {
  st = (vp + 1.0) * 0.5;
  gl_Position = vec4(vp * gui_scale, 0.0, 1.0);
}
