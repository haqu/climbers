//
//  VRope.m
//
//  Created by patrick on 16/10/2010.
//

#import "VRope.h"
#import "cocos2d.h"

@implementation VRope

-(id)initWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB spriteSheet:(CCSpriteBatchNode*)spriteSheetArg {
	if((self = [super init])) {
		spriteSheet = spriteSheetArg;
		[self createRope:pointA pointB:pointB];
	}
	return self;
}

-(void)createRope:(CGPoint)pointA pointB:(CGPoint)pointB {
	vPoints = [[NSMutableArray alloc] init];
	vSticks = [[NSMutableArray alloc] init];
	ropeSprites = [[NSMutableArray alloc] init];
	float distance = ccpDistance(pointA,pointB);
//	int segmentFactor = 12; //increase value to have less segments per rope, decrease to have more segments
//	int segmentFactor = 18; //increase value to have less segments per rope, decrease to have more segments
	int segmentFactor = 8; //increase value to have less segments per rope, decrease to have more segments
	numPoints = distance/segmentFactor;
	CGPoint diffVector = ccpSub(pointB,pointA);
	float multiplier = distance / (numPoints-1);
	antiSagHack = 0.1f; //HACK: scale down rope points to cheat sag. set to 0 to disable, max suggested value 0.1
//	antiSagHack = 0.2f; //HACK: scale down rope points to cheat sag. set to 0 to disable, max suggested value 0.1
	for(int i=0;i<numPoints;i++) {
		CGPoint tmpVector = ccpAdd(pointA, ccpMult(ccpNormalize(diffVector),multiplier*i*(1-antiSagHack)));
		VPoint *tmpPoint = [[VPoint alloc] init];
		[tmpPoint setPos:tmpVector.x y:tmpVector.y];
		[vPoints addObject:tmpPoint];
	}
	for(int i=0;i<numPoints-1;i++) {
		VStick *tmpStick = [[VStick alloc] initWith:[vPoints objectAtIndex:i] pointb:[vPoints objectAtIndex:i+1]];
		[vSticks addObject:tmpStick];
	}
	if(spriteSheet!=nil) {
		for(int i=0;i<numPoints-1;i++) {
			VPoint *point1 = [[vSticks objectAtIndex:i] getPointA];
			VPoint *point2 = [[vSticks objectAtIndex:i] getPointB];
			CGPoint stickVector = ccpSub(ccp(point1.x,point1.y),ccp(point2.x,point2.y));
			float stickAngle = ccpToAngle(stickVector);
			CCSprite *tmpSprite = [CCSprite spriteWithBatchNode:spriteSheet rect:CGRectMake(0,0,multiplier,[[[spriteSheet textureAtlas] texture] pixelsHigh])];
//			ccTexParams params = {GL_LINEAR,GL_LINEAR,GL_REPEAT,GL_REPEAT};
//			[tmpSprite.texture setTexParameters:&params];
			[tmpSprite setPosition:ccpMidpoint(ccp(point1.x,point1.y),ccp(point2.x,point2.y))];
			[tmpSprite setRotation:-1 * CC_RADIANS_TO_DEGREES(stickAngle)];
			[spriteSheet addChild:tmpSprite];
			[ropeSprites addObject:tmpSprite];
		}
	}
}

-(void)resetWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB {
	float distance = ccpDistance(pointA,pointB);
	CGPoint diffVector = ccpSub(pointB,pointA);
	float multiplier = distance / (numPoints - 1);
	for(int i=0;i<numPoints;i++) {
		CGPoint tmpVector = ccpAdd(pointA, ccpMult(ccpNormalize(diffVector),multiplier*i*(1-antiSagHack)));
		VPoint *tmpPoint = [vPoints objectAtIndex:i];
		[tmpPoint setPos:tmpVector.x y:tmpVector.y];
		
	}
}

-(void)removeSprites {
	for(int i=0;i<numPoints-1;i++) {
		CCSprite *tmpSprite = [ropeSprites objectAtIndex:i];
		[spriteSheet removeChild:tmpSprite cleanup:YES];
	}
	[ropeSprites removeAllObjects];
	[ropeSprites release];
}

-(void)updateWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB dt:(float)dt {
	//manually set position for first and last point of rope
	[[vPoints objectAtIndex:0] setPos:pointA.x y:pointA.y];
	[[vPoints objectAtIndex:numPoints-1] setPos:pointB.x y:pointB.y];

	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	float sh = screenSize.height;
	
	//update points, apply gravity
	for(int i=1;i<numPoints-1;i++) {
		[[vPoints objectAtIndex:i] applyGravity:dt];
		[[vPoints objectAtIndex:i] update];
		[[vPoints objectAtIndex:i] applyMinY:sh/32];
	}
	
	//contract sticks
//	int iterations = 4;
//	int iterations = 6;
//	int iterations = 8;
	int iterations = 12;
	for(int j=0;j<iterations;j++) {
		for(int i=0;i<numPoints-1;i++) {
			[[vSticks objectAtIndex:i] contract];
		}
	}
}

-(void)updateSprites {
	if(spriteSheet!=nil) {
		for(int i=0;i<numPoints-1;i++) {
			VPoint *point1 = [[vSticks objectAtIndex:i] getPointA];
			VPoint *point2 = [[vSticks objectAtIndex:i] getPointB];
			CGPoint point1_ = ccp(point1.x,point1.y);
			CGPoint point2_ = ccp(point2.x,point2.y);
			float stickAngle = ccpToAngle(ccpSub(point1_,point2_));
			CCSprite *tmpSprite = [ropeSprites objectAtIndex:i];
			[tmpSprite setPosition:ccpMidpoint(point1_,point2_)];
			[tmpSprite setRotation: -CC_RADIANS_TO_DEGREES(stickAngle)];
//			[tmpSprite setScaleX:ccpDistance(point1_, point2_)/16];
		}
	}	
}

-(void)debugDraw {
	//Depending on scenario, you might need to have different Disable/Enable of Client States
	//glDisableClientState(GL_TEXTURE_2D);
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	//glDisableClientState(GL_COLOR_ARRAY);
	//set color and line width for ccDrawLine
	glColor4f(0.0f,0.0f,1.0f,1.0f);
	glLineWidth(5.0f);
	for(int i=0;i<numPoints-1;i++) {
		//"debug" draw
		VPoint *pointA = [[vSticks objectAtIndex:i] getPointA];
		VPoint *pointB = [[vSticks objectAtIndex:i] getPointB];
//		ccDrawPoint(ccp(pointA.x,pointA.y));
//		ccDrawPoint(ccp(pointB.x,pointB.y));
		ccDrawLine(ccp(pointA.x,pointA.y),ccp(pointB.x,pointB.y));
	}
	//restore to white and default thickness
	glColor4f(1.0f,1.0f,1.0f,1.0f);
	glLineWidth(1);
	//glEnableClientState(GL_TEXTURE_2D);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	//glEnableClientState(GL_COLOR_ARRAY);
}

-(void)dealloc {
	for(int i=0;i<numPoints;i++) {
		[[vPoints objectAtIndex:i] release];
		if(i!=numPoints-1)
			[[vSticks objectAtIndex:i] release];
	}
	[vPoints removeAllObjects];
	[vSticks removeAllObjects];
	[vPoints release];
	[vSticks release];
	[super dealloc];
}

@end
