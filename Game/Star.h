/*
 * Climbers
 * https://github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "cocos2d.h"

@interface Star : CCSprite {
    BOOL collected;
}
@property(assign) BOOL collected;
- (id)initWithPosition:(CGPoint)pos;
@end
