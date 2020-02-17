# Videre 
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)

OpenGL/Vulkan examples written in Julia.

The following examples require the STBImage package.

       09_texture_mapping
            
       10_screen_capture
            
       12_debugging_shaders
            
       14_multi_tex
            
       15_phongtextures
            

Simply use `]` to access the package manager in the
julia REPL and run the following command:

pkg>dev https://github.com/Gnimuc/STBImage.jl.git

The following programs still do not work due to unresolved bugs
            
    16_frag_reject
    
    22_geom_shaders
    
    23_tessellation_shaders
                                                
## References
1. [Anton's OpenGL 4 Tutorials](http://antongerdelan.net/opengl/)
2. https://learnopengl.com
3. https://vulkan-tutorial.com

<!--
[OpenGL 4 Shading Language Cookbook (2nd Ed)](http://www.amazon.com/OpenGL-Shading-Language-Cookbook-Edition/dp/1782167021)
[OpenGL Superbible, 6th edition: Comprehensive Tutorial and Reference](http://www.openglsuperbible.com)
[www.learnopengl.com](http://www.learnopengl.com/#!Introduction)
[The Book of Shaders](http://patriciogonzalezvivo.com/2015/thebookofshaders/00/)
[3D Math Primer for Graphics and Game Development (2nd Ed)](http://www.amazon.com/Math-Primer-Graphics-Development-Edition/dp/1568817231)
-->
