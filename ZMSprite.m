//
//  ZMSprite.m
//  ZeptoMan
//
//  Created by Roman Smirnov on 16.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZMSprite.h"

@interface ZMSprite()
{
    NSMutableData *_vertexData;
    NSMutableData *_textureCoordinateData;
    float _width;
    float _height;
}
@property (readonly) int numVertices;
@property (readonly) GLKVector2 *vertices;
@property (readonly) GLKVector2 *textureCoordinates;

- (void) updateVerticies;

@end

@implementation ZMSprite

@synthesize position = _position;
@synthesize rotation = _rotation;
@synthesize velocity = _velocity;
@synthesize spriteAnimation = _spriteAnimation;
@synthesize previousPosition = _previousPosition;
@synthesize nextTurn = _nextTurn;
@synthesize texture = _texture;

- (int)numVertices{
    return 4;
}

- (GLKVector2 *)vertices
{
    if (!_vertexData){
        _vertexData = [NSMutableData dataWithLength:sizeof(GLKVector2) * self.numVertices];
    }
    return [_vertexData mutableBytes];
}

- (GLKVector2 *)textureCoordinates
{
    if (!_textureCoordinateData){
        _textureCoordinateData = [[NSMutableData alloc] initWithLength:sizeof(GLKVector2)*self.numVertices];
    }
    return [_textureCoordinateData mutableBytes];
}

- (float)width
{
    return _width;
}

- (void)setWidth:(float)newWidth
{
    _width = newWidth;
    [self updateVerticies];
}

- (float)height
{
    return _height;
}

- (void)setHeight:(float)newHeight
{
    _height = newHeight;
    [self updateVerticies];
}

- (void)updateVerticies
{
    self.vertices[0] = GLKVector2Make( self.width/2.0, -self.height/2.0);
    self.vertices[1] = GLKVector2Make( self.width/2.0,  self.height/2.0);
    self.vertices[2] = GLKVector2Make(-self.width/2.0,  self.height/2.0);
    self.vertices[3] = GLKVector2Make(-self.width/2.0, -self.height/2.0);
}

- (void)setDefaultTextureCoordinates
{
    self.textureCoordinates[0] = GLKVector2Make(1, 1);
    self.textureCoordinates[1] = GLKVector2Make(1, 0);
    self.textureCoordinates[2] = GLKVector2Make(0, 0);
    self.textureCoordinates[3] = GLKVector2Make(0, 1);
    
}

- (void)renderWithEffect:(GLKBaseEffect *)effect
{
    
    
    if (self.texture) 
    {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        
        effect.texture2d0.envMode = GLKTextureEnvModeReplace;
        effect.texture2d0.target = GLKTextureTarget2D;
        if (self.spriteAnimation){
            effect.texture2d0.name = [self.spriteAnimation currentFrame].name;
        }
        else {
            effect.texture2d0.name = self.texture.name;
        }

        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, self.textureCoordinates);
        
    }
    
    GLKMatrix4 trans = GLKMatrix4MakeTranslation(self.position.x, self.position.y, 0);
    GLKMatrix4 rot = GLKMatrix4MakeRotation(self.rotation, 0, 0, 1);
    effect.transform.modelviewMatrix = GLKMatrix4Multiply(trans, rot);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, self.vertices);
    
    
    [effect prepareToDraw];

    glDrawArrays(GL_TRIANGLE_FAN, 0, self.numVertices);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}


- (void)update:(NSTimeInterval)dt
{
    switch (self.nextTurn) {
        case TURN_DIRECTION_UP:{
            
            float roundedPosX = roundf(self.position.x-0.5);
            float deltaX = abs(self.position.x-0.5 - roundedPosX);
            if (deltaX < 0.02) 
            {
                self.position = GLKVector2Make(roundedPosX + 0.5, self.position.y);                
                self.velocity = GLKVector2Make(0, 3);
                self.rotation = -0.5*M_PI; 
                self.nextTurn = TURN_DIRECTION_NONE;
            } 
                
            break;
        }
            
        case TURN_DIRECTION_DOWN:{
            
            float roundedPosX = roundf(self.position.x-0.5);
            float deltaX = abs(self.position.x-0.5 - roundedPosX);
            if (deltaX < 0.02) 
            {
                self.position = GLKVector2Make(roundedPosX + 0.5, self.position.y);
                self.velocity = GLKVector2Make(0, -3);
                self.rotation = 0.5*M_PI;
                self.nextTurn = TURN_DIRECTION_NONE;
                
            }
            break;   
        }
            
        case TURN_DIRECTION_LEFT:
        {
            float roundedPosY = roundf(self.position.y-0.5);
            float deltaY = abs(self.position.y-0.5 - roundedPosY);
            if (deltaY < 0.02) 
            {
                self.position = GLKVector2Make(self.position.x, roundedPosY + 0.5);
                self.velocity = GLKVector2Make(-3, 0);
                self.rotation = 0;
                self.nextTurn = TURN_DIRECTION_NONE;
            }
            break;
        }
            
        case TURN_DIRECTION_RIGHT:{
            float roundedPosY = roundf(self.position.y-0.5);
            float deltaY = abs(self.position.y-0.5 - roundedPosY);
            if (deltaY < 0.02) 
            {
                self.position = GLKVector2Make(self.position.x, roundedPosY + 0.5);
                self.velocity = GLKVector2Make(3, 0);
                self.rotation = M_PI;
                self.nextTurn = TURN_DIRECTION_NONE;
            }
            break;          
        }
            
        case TURN_DIRECTION_NONE:{
            //do nothing
            break;
        }
            
        default:{
            NSLog(@"%@ : %@ Warning! Unexpected self.nextTurn: %d", self, NSStringFromSelector(_cmd), self.nextTurn);
            break;
            
        }
    }
    
    
    self.previousPosition = self.position;

    GLKVector2 distanceTraveled = GLKVector2MultiplyScalar(self.velocity, dt);
    self.position = GLKVector2Add(self.position, distanceTraveled);
    [self.spriteAnimation update:dt];
}

- (void)restorePosition
{
    self.position = self.previousPosition;
}

@end
