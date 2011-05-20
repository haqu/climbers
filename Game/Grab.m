/*
 * Climbers
 * https://www.github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "Grab.h"

@implementation Grab

- (id)initWithPosition:(CGPoint)pos {
	if((self = [super initWithSpriteFrameName:@"grab.png"])) {
		self.position = pos;
	}
	return self;
}

@end
