//
//  VRope.h - 0.3
//
//  Updated by patrick on 28/10/2010.
//

/*
Verlet Rope for cocos2d
 
Visual representation of a rope with Verlet integration.
The rope can't (quite obviously) collide with objects or itself.
This was created to use in conjuction with Box2d's new b2RopeJoint joint, although it's not strictly necessary.
Use a b2RopeJoint to physically constrain two bodies in a box2d world and use VRope to visually draw the rope in cocos2d. (or just draw the rope between two moving or static points)

*** IMPORTANT: VRope does not create the b2RopeJoint. You need to handle that yourself, VRope is only responsible for rendering the rope
*** By default, the rope is fixed at both ends. If you want a free hanging rope, modify VRope.h and VRope.mm to only take one body/point and change the update loops to include the last point. 
 
HOW TO USE:
Import VRope.h into your class
 
CREATE:
To create a verlet rope, you need to pass two b2Body pointers (start and end bodies of rope)
and a CCSpriteBatchNode that contains a single sprite for the rope's segment. 
The sprite should be small and tileable horizontally, as it gets repeated with GL_REPEAT for the necessary length of the rope segment.

ex:
CCSpriteBatchNode *ropeSegmentSprite = [CCSpriteBatchNode batchNodeWithFile:@"ropesegment.png" ]; //create a spritesheet 
[self addChild:ropeSegmentSprite]; //add batchnode to cocos2d layer, vrope will be responsible for creating and managing children of the batchnode, you "should" only have one batchnode instance
VRope *verletRope = [[VRope alloc] init:bodyA pointB:bodyB spriteSheet:ropeSegmentSprite];

 
UPDATING:
To update the verlet rope you need to pass the time step
ex:
[verletRope updateRope:dt];

 
DRAWING:
From your layer's draw loop, call the updateSprites method
ex:
[verletRope updateSprites];

Or you can use the debugDraw method, which uses cocos2d's ccDrawLine method
ex:
[verletRope debugDraw];
 
REMOVING:
To remove a rope you need to call the removeSprites method and then release:
[verletRope removeSprites]; //remove the sprites of this rope from the spritebatchnode
[verletRope release];
 
There are also a few helper methods to use the rope without box2d bodies but with CGPoints only.
Simply remove the Box2D.h import and use the "WithPoints" methods.
 

For help you can find me on the cocos2d forums, username: patrickC
Good luck :) 

*/
#import <Foundation/Foundation.h>
#import "VPoint.h"
#import "VStick.h"
#import "cocos2d.h"

//PTM_RATIO defined here is for testing purposes, it should obviously be the same as your box2d world or, better yet, import a common header where PTM_RATIO is defined
#define PTM_RATIO 32

@interface VRope : NSObject {
	int numPoints;
	NSMutableArray *vPoints;
	NSMutableArray *vSticks;
	NSMutableArray *ropeSprites;
	CCSpriteBatchNode* spriteSheet;
	float antiSagHack;
}
-(id)initWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB spriteSheet:(CCSpriteBatchNode*)spriteSheetArg;
-(void)createRope:(CGPoint)pointA pointB:(CGPoint)pointB;
-(void)resetWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB;
-(void)updateWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB dt:(float)dt;
-(void)debugDraw;
-(void)updateSprites;
-(void)removeSprites;

@end
