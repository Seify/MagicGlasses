//
//  ZMSprite.h
//  ZeptoMan
//
//  Created by Roman Smirnov on 16.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLKit/GLKit.h"
#import "ZMSpriteAnimation.h"

typedef int turnDirection;

enum turnDirection{
    TURN_DIRECTION_NONE,
    TURN_DIRECTION_LEFT,
    TURN_DIRECTION_RIGHT,
    TURN_DIRECTION_UP,
    TURN_DIRECTION_DOWN
};

@interface ZMSprite : NSObject
@property float width;
@property float height;
@property GLKVector2 position;
@property GLKVector2 previousPosition;
@property float rotation;
@property GLKVector2 velocity;
@property (strong) ZMSpriteAnimation *spriteAnimation;
@property turnDirection nextTurn;
@property (strong) GLKTextureInfo *texture;    


//- (void)setTextureImage:(UIImage *)image;
- (void)setDefaultTextureCoordinates;
- (void)renderWithEffect:(GLKBaseEffect *)effect;
- (void)update:(NSTimeInterval)dt;
- (void)restorePosition;
@end
