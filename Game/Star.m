/*
 * Climbers
 * https://github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "Star.h"

@implementation Star

@synthesize collected;

- (id)initWithPosition:(CGPoint)pos {
	if((self = [super initWithSpriteFrameName:@"star.png"])) {
		self.position = pos;
		collected = NO;
	}
	return self;
}

@end
