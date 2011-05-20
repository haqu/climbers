//
//  VStick.m
//
//  Created by patrick on 14/10/2010.
//

#import "VStick.h"
#import	 "cocos2d.h"

@implementation VStick
-(id)initWith:(VPoint*)argA pointb:(VPoint*)argB {
	if((self = [super init])) {
		pointA = argA;
		pointB = argB;
		hypotenuse = ccpDistance(ccp(pointA.x,pointA.y),ccp(pointB.x,pointB.y));
	}
	return self;
}

-(void)contract {
	float dx = pointB.x - pointA.x;
	float dy = pointB.y - pointA.y;
	float h = ccpDistance(ccp(pointA.x,pointA.y),ccp(pointB.x,pointB.y));
	float diff = hypotenuse - h;
	float offx = (diff * dx / h) * 0.5;
	float offy = (diff * dy / h) * 0.5;
	pointA.x-=offx;
	pointA.y-=offy;
	pointB.x+=offx;
	pointB.y+=offy;
}
-(VPoint*)getPointA {
	return pointA;
}
-(VPoint*)getPointB {
	return pointB;
}
@end
