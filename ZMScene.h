//
//  ZMScene.h
//  ZeptoMan
//
//  Created by Roman Smirnov on 16.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

typedef int sceneState;

enum sceneState{
    SCENE_STATE_PLAYING,
    SCENE_STATE_PAUSED
};

@interface ZMScene : NSObject
{
    
}
@property float left, right, bottom, top;

- (void)setupGL;
- (void)tearDownGL;

- (void)swipe:(UISwipeGestureRecognizerDirection)direction;
- (void)update:(NSTimeInterval)dt;
- (void)render;

@end
