//
//  Shader.fsh
//  MagicGlasses
//
//  Created by Roman Smirnov on 24.06.12.
//  Copyright (c) 2012 Roman Smirnov. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
