//
//  ZMSpriteAnimation.m
//  ZeptoMan
//
//  Created by Roman Smirnov on 16.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZMSpriteAnimation.h"

@interface ZMSpriteAnimation()
{
    NSArray *_frames;
    float _timePerFrame;
    float _elapsedTime;
}
@end

@implementation ZMSpriteAnimation

//- (id)initWithTimePerFrame:(float)timePerFrame framesNamed:(NSArray *)frameNames
//{
//        if(self = [super init])
//        {
//            _timePerFrame = timePerFrame;
//            
//            _elapsedTime = 0;
//            
//            NSMutableArray *tempArray = [NSMutableArray array];
//            
//            for (NSString *name in frameNames) {
//                if (![name isKindOfClass:[NSString class]]){
//                    NSLog(@"%@ : %@ Warning! Unexpected name in array: %@", self, NSStringFromSelector(_cmd), name);
//                } else {
//                    NSError *error;
//                    UIImage *image = [UIImage imageNamed:name];
//                    [tempArray addObject:[GLKTextureLoader textureWithCGImage:image.CGImage
//                                                                      options:nil 
//                                                                        error:&error]];
//                    if (error){
//                        NSLog(@"%@ : %@ Warning! Failed to load texture. Error: %@", self, NSStringFromSelector(_cmd), error);
//                    }
//                     
//                }
//            }
//            
//            _frames = tempArray;
//            
//        }
//    
//    return self;
//};

- (id)initWithTimePerFrame:(float)timePerFrame frames:(NSArray *)frames
{
    if(self = [super init])
    {
        _timePerFrame = timePerFrame;
        _elapsedTime = 0;
        _frames = frames;
    }
    
    return self;
};

- (void)update:(NSTimeInterval)dt
{
    _elapsedTime += dt;
}

- (GLKTextureInfo *)currentFrame
{
    return [_frames objectAtIndex:((int)(_elapsedTime/_timePerFrame))%[_frames count]];
}


@end
