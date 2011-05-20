//
//  VPoint.h
//
//  Created by patrick on 14/10/2010.
//

#import <Foundation/Foundation.h>

@interface VPoint : NSObject {
	float x,y,oldx,oldy;
}

@property(nonatomic,assign) float x;
@property(nonatomic,assign) float y;

-(void)setPos:(float)argX y:(float)argY;
-(void)update;
-(void)applyGravity:(float)dt;
- (void)applyMinY:(float)minY;

@end
