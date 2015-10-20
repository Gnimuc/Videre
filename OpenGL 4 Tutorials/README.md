# Anton's OpenGL 4 Tutorials
Note that, this is not a one-to-one correspondence translation from [this repo](https://github.com/capnramses/antons_opengl_tutorials_book).
The only thing I can guarantee is the outputs of those codes are quite the same.

## Index
- [x] **Hello Triangle**

- [x] **Extended Initialization**

- [x] **OpenGL 4 Shaders**

- [x] **Vertex Buffer Objects**

- [x] **Vectors and Matrices**

- [x] **Virtual Camera**

- [ ] **Quaternion Quick-Start**

- [ ] **Ray-Based Picking**

- [ ] **Phong Lighting**

- [ ] **Texture Maps**

- [ ] **Screen Capture**

- [ ] **Video Capture**

- [ ] **Debugging Shaders**

- [ ] **Gamma Correction**

- [ ] **Extension Checks and the Debug Callback**

- [ ] **Uniform Buffer Objects and Buffer Mapping Functions**

- [ ] **Importing a Mesh File**

- [ ] **Multi-Texturing**

- [ ] **Using Texture for Lighting Coefficients**

- [ ] **Fragment Rejection**

- [ ] **Alpha Blending for Transparency**

- [ ] **Spotlights and Directional Lights**

- [ ] **Distance Fog**

- [ ] **Normal Mapping**

- [ ] **Cube Maps: Sky Boxes and Environment Mapping**

- [ ] **Geometry Shaders**

- [ ] **Tessellation Shaders**

- [ ] **2d GUI Panels**

- [ ] **Sprite Sheets and 2d Animation**

- [ ] **Bitmap Fonts**

- [ ] **Making a Font Atlas Generator Tool**

- [ ] **Particle Systems**

- [ ] **Hardware Skinning**

- [ ] **Switching Framebuffer**

- [ ] **Image Processing with a Kernel**

- [ ] **Colour-Based Picking**

- [ ] **Deferred Shading**

- [ ] **Texture Projection Shadows**

- [ ] **Building Larger Programmes**

- [ ] **Closing Remarks, Future Techniques, and Further Reading**

# Code Style
For safety sake, we should use `Ref()` as an analogy to `C`'s `&` instead of `pointer_from_objref` or `pointer`.
That means even referring to a value, we need to define it as a one-element array, take a look at the example below:

```
vboID = GLuint[0]
glGenBuffers(1, Ref(vboID))
glBindBuffer(GL_ARRAY_BUFFER, vboID[])
```

Note that, here we use `vboID[]` rather than `vboID[1]` so as to remand us that `vboID` is supposed to be a value, not an array.

An alternative way is to declare `vobID` as a `Ref{T}` type:

```
vboID = Ref{GLuint}(0)
glGenBuffers(1, vboID)
glBindBuffer(GL_ARRAY_BUFFER, vboID[])
```

In this case, we still need to use `vboID[]`.

I prefer the first one because it looks more like `glGenBuffers(1, &vboID)` in `C`.
