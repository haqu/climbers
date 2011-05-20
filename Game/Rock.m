/*
 * Climbers
 * https://github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "Rock.h"

@implementation Rock

@synthesize velocity, falling;

- (id)initWithPosition:(CGPoint)pos {
	if((self = [super initWithSpriteFrameName:@"rock.png"])) {
		self.position = pos;
		velocity = CGPointZero;
		falling = NO;
	}
	return self;
}

#define kGroundY 32.0f

- (void)update:(ccTime)dt {
	if(self.position.y > kGroundY) {
		velocity = ccpAdd(velocity, ccp(0, -20.0f*dt));
		if(velocity.y < -10.0f) {
			velocity = ccp(0, -10); // limit
		}
		self.position = ccpAdd(self.position, velocity);
	} else if(self.position.y < kGroundY) {
		self.position = ccp(self.position.x, kGroundY);
		falling = NO;
		velocity = CGPointZero;
	}
}

@end
