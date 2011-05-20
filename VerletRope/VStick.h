//
//  VStick.h
//
//  Created by patrick on 14/10/2010.
//

#import <Foundation/Foundation.h>
#import "VPoint.h"

@interface VStick : NSObject {
	VPoint *pointA;
	VPoint *pointB;
	float hypotenuse;
}
-(id)initWith:(VPoint*)argA pointb:(VPoint*)argB;
-(void)contract;
-(VPoint*)getPointA;
-(VPoint*)getPointB;
@end
