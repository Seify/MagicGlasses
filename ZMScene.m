//
//  ZMScene.m
//  ZeptoMan
//
//  Created by Roman Smirnov on 16.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZMScene.h"
#import "ZMSprite.h"

@interface ZMScene()
{
    sceneState state;
    
    GLKTextureInfo *coinTexture;    
    GLKTextureInfo *playerTexture1;    
    GLKTextureInfo *playerTexture2;    
    GLKTextureInfo *enemyTexture;    
    GLKTextureInfo *wallTexture;    
}
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation ZMScene

@synthesize effect = _effect;
@synthesize left = _left, right = _right, bottom = _bottom, top = _top;

- (void)loadInitialPosition
{
    NSError *error;
    
}

- (id)init
{
    if (self = [super init]){
        
        state = SCENE_STATE_PLAYING;
        
    }
    return self;
}

- (void)setupGL
{
    self.effect = [[GLKBaseEffect alloc] init];    
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        self.left   = -9;
        self.right  =  9;
        self.bottom = -6;
        self.top    =  6;
    } else {
        self.left   = -8;
        self.right  =  8;
        self.bottom = -6;
        self.top    =  6;
    }
    
    self.effect.transform.projectionMatrix = GLKMatrix4MakeOrtho(self.left, self.right, self.bottom, self.top, 1, -1);
}

- (void)tearDownGL
{
    self.effect = nil;
    state = SCENE_STATE_PAUSED;

}

# pragma mark - Gesture handlers

- (void)swipe:(UISwipeGestureRecognizerDirection)direction
{
    switch (direction) {
        case UISwipeGestureRecognizerDirectionUp:{

            break;
        }
            
        case UISwipeGestureRecognizerDirectionDown:{

            break;
        }
            
        case UISwipeGestureRecognizerDirectionRight:{

            break;
        }
            
        case UISwipeGestureRecognizerDirectionLeft:{

            break;
        }
            
        default:{
            NSLog(@"%@ : %@ Warning! Unexpected direction: %@", self, NSStringFromSelector(_cmd), direction);
            break;
        }
    }
}

#pragma mark - Physics & Game Logic

- (BOOL)areRectangle:(CGRect)r1 IntersectsWithRectangle:(CGRect)r2
{
    float left1 = r1.origin.x;
    float left2 = r2.origin.x;
    
    float right1 = r1.origin.x + r1.size.width;
    float right2 = r2.origin.x + r2.size.width;
    
    float bottom1 = r1.origin.y;
    float bottom2 = r2.origin.y;
    
    float top1 = r1.origin.y + r1.size.height;
    float top2 = r2.origin.y + r2.size.height;
    
    if(bottom1 > top2) {
        return NO;   
    }
    if(top1 < bottom2){
        return NO;   
    }
    if(right1 < left2){
        return NO;   
    }
    if(left1 > right2) {
        return NO;   
    }
    return YES;
}

- (BOOL)doesSprite:(ZMSprite *)sprite1 intersectsWithSprite:(ZMSprite *)sprite2
{
    CGRect spriteBox1 = CGRectMake(sprite1.position.x - sprite1.width/2.0, sprite1.position.y - sprite1.height/2.0, sprite1.width, sprite1.height);
    CGRect spriteBox2 = CGRectMake(sprite2.position.x - sprite2.width/2.0, sprite2.position.y - sprite2.height/2.0, sprite2.width, sprite2.height);
    if ([self areRectangle:spriteBox1 IntersectsWithRectangle:spriteBox2]){
        return YES;
    }
    return NO;
}


- (void)update:(NSTimeInterval)dt
{

    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self loadInitialPosition];
    state = SCENE_STATE_PLAYING;
}

# pragma mark - Graphics

- (void)render
{
    if (state == SCENE_STATE_PLAYING)
    {
    
        glClearColor(0.5f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);   

        
    }
    
}

@end
