/*
 * Climbers
 * https://www.github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "cocos2d.h"

typedef enum {
	kHeroStateIdle,
	kHeroStateDrag,
	kHeroStateGrab,
	kHeroStateFall,
} HeroState;

@interface Hero : CCSprite {
    CGPoint velocity;
	HeroState state;
	float topGroundY;
	float bottomGroundY;
}
@property(nonatomic,assign) CGPoint velocity;
@property(nonatomic,assign) HeroState state;
@property(nonatomic,assign) float topGroundY;
@property(nonatomic,assign) float bottomGroundY;
- (id)initWithPosition:(CGPoint)pos;
- (void)update:(ccTime)dt;
@end
