//
//  VPoint.m
//
//  Created by patrick on 14/10/2010.
//

#import "VPoint.h"

@implementation VPoint

@synthesize x;
@synthesize y;

-(void)setPos:(float)argX y:(float)argY {
	x = oldx = argX;
	y = oldy = argY;
}

-(void)update {
	float tempx = x;
	float tempy = y;
	x += x - oldx;
	y += y - oldy;
	oldx = tempx;
	oldy = tempy;
}

-(void)applyGravity:(float)dt {
	y -= 10.0f*dt; //gravity magic number
}

- (void)applyMinY:(float)minY {
	// hack for ground collision [haqu]
	if(y<minY) {
		y = minY;
		// stop motion
		oldx = x; 
		oldy = y;
	}
}

-(void)setX:(float)argX {
	x = argX;
}

-(void)setY:(float)argY {
	y = argY;
}

-(float)getX {
	return x;
}

-(float)getY {
	return y;
}

@end
