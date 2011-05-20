/*
 * Climbers
 * https://www.github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "Hero.h"

@implementation Hero

@synthesize velocity, state, topGroundY, bottomGroundY;

- (id)initWithPosition:(CGPoint)pos {
	if((self = [super initWithSpriteFrameName:@"hero.png"])) {
		self.position = pos;
		velocity = CGPointZero;
		topGroundY = self.position.y;
		bottomGroundY = self.position.y;
		self.state = kHeroStateIdle;
	}
	return self;
}

- (void)setState:(HeroState)s {
	if(state == s) return;
	state = s;
	switch(state) {
		case kHeroStateDrag:
		case kHeroStateFall:
			[self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"heroDrag.png"]];
			break;
		case kHeroStateGrab:
			[self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"heroGrab.png"]];
			break;
		default:
			[self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"hero.png"]];
			break;
	}
	velocity = CGPointZero;
}

- (void)update:(ccTime)dt {
	if(state == kHeroStateFall) {
		BOOL overTop = NO;
		if(self.position.y > topGroundY) overTop = YES;
		if(self.position.y > bottomGroundY) {
			velocity = ccpAdd(velocity, ccp(0, -20.0f*dt));
			self.position = ccpAdd(self.position, velocity);
		}
		if(overTop && self.position.y <= topGroundY) {
			self.position = ccp(self.position.x, topGroundY);
			self.state = kHeroStateIdle;
		} else if(self.position.y <= bottomGroundY) {
			self.position = ccp(self.position.x, bottomGroundY);
			self.state = kHeroStateIdle;
		}
	}
}

@end
