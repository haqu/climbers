/*
 * Climbers
 * https://www.github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "Game.h"
#import "Hero.h"
#import "VRope.h"
#import "Grab.h"
#import "Star.h"
#import "Rock.h"
#import "Intro.h"
#import "SimpleAudioEngine.h"
#import "GameConfig.h"
#ifdef MAC
#import "CDXMacOSXSupport.h"
#endif

#ifdef IOS
#define kFontName @"ChalkboardSE-Bold"
#else
#define kFontName @"Arial"
#endif

#define kNumLevels 15

enum {
	kTagLabel = 1,
	kTagLabel2,
	kTagLabel3,
	kTagBottom,
	kTagTop,
	kTagWall,
	kTagFlower,
	kTagFlowerPS,
};

@interface Game()
- (void)loadLevel;
- (void)resetLevel;
- (void)tapDownAt:(CGPoint)location;
- (void)tapMoveAt:(CGPoint)location;
- (void)tapUpAt:(CGPoint)location;
- (void)sparkleAt:(CGPoint)p;
- (void)updateCamera;
- (BOOL)dragHeroNearGrab:(Grab*)g;
- (void)scheduleRockAlert;
- (void)showRockAlert;
- (void)dropRock;
- (void)updateDragHeroPositionWithTouchLocation:(CGPoint)touchLocation;
- (void)updateStarsCollectedLabel;
- (void)updateUIPosition;
- (void)showPopupMenu;
@end

@implementation Game

+ (CCScene*)scene {
	CCScene *scene = [CCScene node];
	[scene addChild:[Game node]];
	return scene;
}

- (id)init {
	if((self = [super init])) {
		
#ifdef IOS
		self.isTouchEnabled = YES;
#else
		self.isMouseEnabled = YES;
#endif
		dragInProgress = NO;
		dragHero = nil;
		dragOtherHero = nil;
		
		CGSize screenSize = [[CCDirector sharedDirector] winSize];
		sw = screenSize.width;
		sh = screenSize.height;
		
		ropeLength = sh*250/1024;
		heroStarDist = sh*48.0f/1024;
		heroRockDist = sh*64.0f/1024;
		snapDist = sh*64.0f/1024;
		
		// sprite sheet
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sprites.plist"];
		batch1 = [[CCSpriteBatchNode alloc] initWithFile:@"sprites.png" capacity:50];
		[self addChild:batch1];
		batch2 = [[CCSpriteBatchNode alloc] initWithFile:@"sprites.png" capacity:50];
		[self addChild:batch2 z:10];

		// heroes and rope
		hero1 = [[Hero alloc] initWithPosition:ccp(sw/2-ropeLength/2.0f,sh/16)];
		[batch2 addChild:hero1];
		hero2 = [[Hero alloc] initWithPosition:ccp(sw/2+ropeLength/2.0f,sh/16)];
		[batch2 addChild:hero2];

		ropeBatch = [CCSpriteBatchNode batchNodeWithFile:@"rope.png"];
		rope = [[VRope alloc] initWithPoints:hero1.position pointB:hero2.position spriteSheet:ropeBatch];

		[self addChild:ropeBatch z:1];
		
		// snap feedback
		snapFeedback = [[CCSprite alloc] initWithSpriteFrameName:@"snapFeedback.png"];
		[batch1 addChild:snapFeedback];
		snapFeedback.opacity = 0;
		
		// rock
		rock = [[Rock alloc] initWithPosition:CGPointZero];
		rock.opacity = 0;
		[batch1 addChild:rock z:10];
		
		// rock alert
		rockAlert = [[CCSprite alloc] initWithSpriteFrameName:@"rockAlert.png"];
		[batch1 addChild:rockAlert z:13];
		rockAlert.opacity = 0;
		
		// star icon
		CCSprite *sprite;
		sprite = [CCSprite spriteWithSpriteFrameName:@"starIcon.png"];
		sprite.position = ccp(32,sh-32);
		[batch1 addChild:sprite z:15];
		starIcon = [sprite retain];
		
		// menu button
		sprite = [CCSprite spriteWithSpriteFrameName:@"menuButton.png"];
		sprite.position = ccp(sw-32,sh-32);
		[batch1 addChild:sprite z:15];
		menuButton = [sprite retain];

		// star counter
		float fontSize = 24;
		if(IS_IPHONE) fontSize = 12;
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:@"0/0" fntFile:@"digits.fnt"];
		label.opacity = 128;
		label.position = ccp(60,sh-32);
		label.anchorPoint = ccp(0,0.5f);
		[self addChild:label z:15];
		starsCollectedLabel = [label retain];
		
		// arrays
		grabs = [[NSMutableArray alloc] init];
		stars = [[NSMutableArray alloc] init];
		
		rockTimer = nil;
		
		currentLevel = 0;
		nextLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentLevel"];
		if(!nextLevel) {
			nextLevel = 1;
		}
		[self resetLevel];
		
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"levelCompleted.caf"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"levelFailed.caf"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"click.caf"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"grab.caf"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"collectStar.mp3"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"dropRock.mp3"];

		[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"game.mp3" loop:YES];
		
		[self schedule:@selector(update:)];
	}
	return self;
}

- (void)dealloc {
	[starIcon release];
	[starsCollectedLabel release];
	[menuButton release];
	[stars release];
	[grabs release];
	[rockAlert release];
	[rock release];
	[snapFeedback release];
	[rope removeSprites];
	[rope release];
	[hero2 release];
	[hero1 release];
	[batch1 release];
	[batch2 release];
	[super dealloc];
}

- (void)loadLevel {
	NSString *basename = [NSString stringWithFormat:@"%02d",currentLevel];
	NSString *path = [[NSBundle mainBundle] pathForResource:basename ofType:@"svg"];
	NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	NSScanner *scanner = [NSScanner scannerWithString:content];

	[scanner scanUpToString:@"wall" intoString:nil];
	[scanner scanUpToString:@"height" intoString:nil];
	[scanner scanString:@"height=\"" intoString:nil];
	[scanner scanFloat:&levelHeight];
	levelHeight = levelHeight*sh/1024;

	[self removeChildByTag:kTagWall cleanup:YES];
	CCSprite *wall = [CCSprite spriteWithFile:@"wall.png" rect:CGRectMake(0, 0, sw, levelHeight)];
	wall.position = ccp(sw/2, levelHeight/2.0f);
	[self addChild:wall z:-2 tag:kTagWall];
	ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
	[wall.texture setTexParameters:&tp];
	
	startPosition1 = ccp(sw/2-ropeLength/3,sh/16);
	startPosition2 = ccp(sw/2+ropeLength/3,sh/16);
	
	// grabs and stars
	if([grabs count]) {
		for(Grab *g in grabs) {
			[batch1 removeChild:g cleanup:YES];
		}
		[grabs removeAllObjects];
	}
	if([stars count]) {
		for(Star *s in stars) {
			[batch1 removeChild:s cleanup:YES];
		}
		[stars removeAllObjects];
	}
	starsTotal = 0;
	Grab *grab;
	Star *star;
	float x, y;
	BOOL isGrab; // grab or star
	CGPoint p;
	
	while(true) {
		isGrab = NO;
		if(![scanner scanUpToString:@"circle" intoString:nil]) break;
		if([scanner isAtEnd]) break;
		[scanner scanUpToString:@"id" intoString:nil];
		if([scanner scanString:@"id=\"grab" intoString:nil]) {
			isGrab = YES;
		} else if([scanner scanString:@"id=\"star" intoString:nil]) {
			isGrab = NO;
		}
		[scanner scanUpToString:@"cx" intoString:nil];
		[scanner scanString:@"cx=\"" intoString:nil];
		[scanner scanFloat:&x];
		[scanner scanUpToString:@"cy" intoString:nil];
		[scanner scanString:@"cy=\"" intoString:nil];
		[scanner scanFloat:&y];
		p = ccp(x*sw/768,sh-y*sh/1024);
		if(isGrab) {
			grab = [[Grab alloc] initWithPosition:p];
			[grabs addObject:grab];
			[batch1 addChild:grab z:5];
			[grab release];
		} else {
			star = [[Star alloc] initWithPosition:p];
			[stars addObject:star];
			[batch1 addChild:star z:6];
			[star release];
			starsTotal++;
		}
	}

	[batch1 removeChildByTag:kTagBottom cleanup:YES];
	CCSprite *bottom = [CCSprite spriteWithSpriteFrameName:@"bottom.png"];
	bottom.position = ccp(sw/2, sh/32);
	bottom.tag = kTagBottom;
	[batch1 addChild:bottom z:11];
	
	[batch1 removeChildByTag:kTagTop cleanup:YES];
	CCSprite *top = [CCSprite spriteWithSpriteFrameName:@"top.png"];
	top.position = ccp(sw/2, levelHeight);
	top.tag = kTagTop;
	[batch1 addChild:top z:11];

	[batch1 removeChildByTag:kTagFlower cleanup:YES];
	CCSprite *flower = [CCSprite spriteWithSpriteFrameName:@"flower.png"];
	flower.position = ccp(sw/2, levelHeight);
	flower.tag = kTagFlower;
	[batch1 addChild:flower z:12];
}

- (void)resetLevel {
	
	if(nextLevel != currentLevel) {
		currentLevel = nextLevel;
		if(currentLevel > kNumLevels) {
			[[CCDirector sharedDirector] pushScene:[Intro scene]];
			return;
		}
		[self loadLevel];
	}
	
	[self removeChildByTag:kTagLabel cleanup:YES];
	[self removeChildByTag:kTagLabel2 cleanup:YES];
	[self removeChildByTag:kTagLabel3 cleanup:YES];
	
	[self removeChildByTag:kTagFlowerPS cleanup:YES];
	
	hero1.state = kHeroStateIdle;
	hero2.state = kHeroStateIdle;
	hero1.position = startPosition1;
	hero2.position = startPosition2;
	hero1.topGroundY = levelHeight+sh*36/1024;
	hero2.topGroundY = levelHeight+sh*36/1024;
	[rope resetWithPoints:hero1.position pointB:hero2.position];

	for(Star *s in stars) {
		if(s.collected) {
			s.collected = NO;
			id a1 = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
			id a2 = [CCFadeIn actionWithDuration:0.5f];
			[s runAction:[CCSpawn actions:a1,a2,nil]];
		}
	}
	starsCollected = 0;
	[self updateStarsCollectedLabel];

	if(snapFeedback.opacity > 0) {
		[snapFeedback runAction:[CCFadeOut actionWithDuration:0.25f]];
	}
	
	cameraOffset = CGPointZero;
	[self stopAllActions];
	self.position = CGPointZero;

	[self updateUIPosition];
	
	if(rock.falling) {
		rock.falling = NO;
		rock.opacity = 0;
	}
	
	dragInProgress = NO;
	gameInProgress = YES;
	[self scheduleRockAlert];
}

- (void)levelFailed {
	NSLog(@"levelFailed");
	[[SimpleAudioEngine sharedEngine] playEffect:@"levelFailed.caf"];
	gameInProgress = NO;
	if(rockTimer) {
		[rockTimer invalidate];
		rockTimer = nil;
	}
	if(rock.opacity > 0) {
		[rock runAction:[CCFadeOut actionWithDuration:0.5f]];
	}
	float fontSize = 64.0f;
	if(IS_IPHONE) fontSize = 32.0f;
	CCLabelTTF *label = [CCLabelTTF labelWithString:@"NO-O-O-O!" fontName:kFontName fontSize:fontSize];
	label.color = ccc3(240, 0, 0);
	label.position = ccp(sw/2, sh*7/8-self.position.y);
	label.tag = kTagLabel;
	[self addChild:label z:12];
	nextLevel = currentLevel;
}

- (void)levelCompleted {
	NSLog(@"levelCompleted");
	[[SimpleAudioEngine sharedEngine] playEffect:@"levelCompleted.caf"];
	gameInProgress = NO;
	if(rockTimer) {
		[rockTimer invalidate];
		rockTimer = nil;
	}
	float fontSize = 64.0f;
	if(IS_IPHONE) fontSize = 32.0f;
	CCLabelTTF *label;
	if(currentLevel == kNumLevels) {
		label = [CCLabelTTF labelWithString:@"Yeah! You did it!" fontName:kFontName fontSize:fontSize];
		label.color = ccc3(255, 255, 255);
		label.position = ccp(sw/2, levelHeight+sh*3/8);
		label.tag = kTagLabel;
		[self addChild:label z:12];
		
		label = [CCLabelTTF labelWithString:@"Finally, you overcame all difficulties on your way. Great job!" fontName:kFontName fontSize:fontSize*3/8];
		label.color = ccc3(255, 255, 255);
		label.position = ccp(sw/2, levelHeight+sh*5/16);
		label.tag = kTagLabel2;
		[self addChild:label z:12];

//		label = [CCLabelTTF labelWithString:@"Tap to go back to start screen" fontName:kFontName fontSize:fontSize/4];
//		label.color = ccc3(255, 255, 255);
//		label.position = ccp(sw/2, levelHeight+sh*17/64);
//		label.tag = kTagLabel3;
//		[self addChild:label z:12];
		
	} else {
		label = [CCLabelTTF labelWithString:@"Well Done!" fontName:kFontName fontSize:fontSize];
		label.color = ccc3(255, 255, 255);
		label.position = ccp(sw/2, levelHeight+sh*3/8);
		label.tag = kTagLabel;
		[self addChild:label z:12];
		
		label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Level %d completed",currentLevel] fontName:kFontName fontSize:fontSize*3/8];
		label.color = ccc3(255, 255, 255);
		label.position = ccp(sw/2, levelHeight+sh*5/16);
		label.tag = kTagLabel2;
		[self addChild:label z:12];
		
//		label = [CCLabelTTF labelWithString:@"Tap to continue" fontName:kFontName fontSize:fontSize*3/8];
//		label.color = ccc3(255, 255, 255);
//		label.position = ccp(sw/2, levelHeight-sh*3/8);
//		label.tag = kTagLabel3;
//		[self addChild:label z:12];
	}
	
	CCParticleSystem *ps = [CCParticleFireworks node];
	ps.texture = [[CCTextureCache sharedTextureCache] addImage:@"stars.png"];
	ps.startSize = 4;
//	ps.endSize = 10.0f;
	ps.speed = 100;
	ps.position = ccp(sw/2-sw*9/768, levelHeight+sh*65/1024);
	[self addChild:ps z:10 tag:kTagFlowerPS];
	
	nextLevel = currentLevel+1;
	if(nextLevel > kNumLevels) {
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"currentLevel"];
	} else {
		[[NSUserDefaults standardUserDefaults] setInteger:nextLevel forKey:@"currentLevel"];
	}
	
//	[self sparkleAt:ccp(384-8, levelHeight+64)];
}

- (void)update:(ccTime)dt {
	if(gameInProgress && [self numberOfRunningActions]) {
		if(dragInProgress) {
			[self updateDragHeroPositionWithTouchLocation:lastTouchLocation];
		}
	}
	[hero1 update:dt];
	[hero2 update:dt];
//	if((hero1.position.y == 64 || hero2.position.y == 64) && cameraOffset.y > 0) {
//		cameraOffset = CGPointZero;
//		[self updateCamera];
//	}
	if(gameInProgress && !dragInProgress) {
		// standing on top
		if(hero1.position.y >= hero1.topGroundY && hero2.position.y >= hero2.topGroundY) {
			cameraOffset = CGPointMake(0, levelHeight-sh/2);
			[self updateCamera];
			[self levelCompleted];
		}
		// falling down
		if(hero1.state != hero2.state && (hero1.state == kHeroStateFall || hero2.state == kHeroStateFall)) {
			float dist = ccpDistance(hero1.position, hero2.position);
			if(dist > ropeLength) {
				hero1.state = kHeroStateFall;
				hero2.state = kHeroStateFall;
				float vy = MIN(hero1.velocity.y, hero2.velocity.y);
				hero1.velocity = ccp(0,vy);
				hero2.velocity = ccp(0,vy);
				if(hero1.position.y > sh/2 || hero2.position.y > sh/2) {
					[self levelFailed];
				}
			}
		}
	}
	[rope updateWithPoints:hero1.position pointB:hero2.position dt:dt];
	[rope updateSprites];

	// if camera moving
	if([self numberOfRunningActions]) {
		[self updateUIPosition];
		if([rockAlert numberOfRunningActions] && -self.position.y <= levelHeight-sh) {
			rockAlert.position = ccp(rockAlert.position.x, sh*31/32-self.position.y);
		}
	}
	
	if(gameInProgress && rock.falling) {
		[rock update:dt];
		if(!rock.falling && rock.opacity > 0) {
			[rock runAction:[CCFadeOut actionWithDuration:0.5f]];
		}
		if(gameInProgress && rock.opacity > 0 && (hero1.state != kHeroStateIdle || hero2.state != kHeroStateIdle)) {
			if(ccpDistance(hero1.position, rock.position) < heroRockDist ||
			   ccpDistance(hero2.position, rock.position) < heroRockDist) {
				hero1.state = kHeroStateFall;
				hero1.velocity = rock.velocity;
				hero2.state = kHeroStateFall;
				hero2.velocity = rock.velocity;
				[self levelFailed];
			}
		}
	}
}

- (void)registerWithTouchDispatcher {
#ifdef IOS
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
#else
	[[CCEventDispatcher sharedDispatcher] addMouseDelegate:self priority:0];
#endif
}

- (void)tapDownAt:(CGPoint)location {

	// menu button
	CGRect rect = CGRectMake(menuButton.position.x-32, menuButton.position.y-32+self.position.y, 64, 64);
	NSLog(@"tapDownAt (%f.1,%.1f)",location.x,location.y);
	NSLog(@"menuButton rect (%.1f,%.1f,%.1f,%.1f)",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
	if(CGRectContainsPoint(rect, location)) {
		[self showPopupMenu];
		return;
	}

	if(!gameInProgress) {
		[self resetLevel];
		[[SimpleAudioEngine sharedEngine] playEffect:@"grab.caf"];
		return;
	}

	lastTouchLocation = location;
	location = ccpSub(location, self.position);
	
	static float tapRadius = 64.0f;
	
	if(ccpDistance(hero1.position, location) < tapRadius) {
		dragHero = hero1;
		dragOtherHero = hero2;
		if(dragOtherHero.state != kHeroStateFall) {
			dragInProgress = YES;
			dragOffset = ccpSub(dragHero.position, location);
			dragHero.state = kHeroStateDrag;
			[[SimpleAudioEngine sharedEngine] playEffect:@"click.caf"];
		}
		return;
	}
	if(ccpDistance(hero2.position, location) < tapRadius) {
		dragHero = hero2;
		dragOtherHero = hero1;
		if(dragOtherHero.state != kHeroStateFall) {
			dragInProgress = YES;
			dragOffset = ccpSub(dragHero.position, location);
			dragHero.state = kHeroStateDrag;
			[[SimpleAudioEngine sharedEngine] playEffect:@"click.caf"];
		}
		return;
	}
}

- (void)tapMoveAt:(CGPoint)location {
	if(!gameInProgress) return;
	
	lastTouchLocation = location;
	
	if(dragInProgress) {
		[self updateDragHeroPositionWithTouchLocation:lastTouchLocation];
	}
}

- (void)tapUpAt:(CGPoint)location {
	if(!gameInProgress) return;
	
	if(dragInProgress) {
		dragInProgress = NO;
		dragHero.state = kHeroStateFall;
		[[SimpleAudioEngine sharedEngine] playEffect:@"grab.caf"];
		if(snapFeedback.opacity > 0) {
			[snapFeedback runAction:[CCFadeOut actionWithDuration:0.25f]];
		}
		if(dragHero.position.y > dragHero.topGroundY-snapDist && dragHero.position.y <= dragHero.topGroundY) {
			dragHero.position = ccp(dragHero.position.x, dragHero.topGroundY);
			dragHero.state = kHeroStateIdle;
			return;
		}
		for (Grab *g in grabs) {
			if([self dragHeroNearGrab:g]) {
				dragHero.position = g.position;
				dragHero.state = kHeroStateGrab;
				cameraOffset = CGPointMake(0, dragHero.position.y-sh/2);
				if(cameraOffset.y < 0) cameraOffset = CGPointZero;
				[self updateCamera];
				return;
			}
		}
		if(dragHero.position.y < 200) {
			cameraOffset = CGPointZero;
			[self updateCamera];
		}
	}
}

#ifdef IOS
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	[self tapDownAt:location];
	return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	[self tapMoveAt:location];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	[self tapUpAt:location];
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	[self tapUpAt:location];
}

#else // MAC

- (BOOL)ccMouseDown:(NSEvent *)event {
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	[self tapDownAt:location];
	return YES;
}

- (BOOL)ccMouseDragged:(NSEvent *)event {
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	[self tapMoveAt:location];
	return YES;
}

- (BOOL)ccMouseUp:(NSEvent *)event {
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	[self tapUpAt:location];
	return YES;
}

#endif // IOS or MAC

- (void)sparkleAt:(CGPoint)p {
//	NSLog(@"sparkle");
	CCParticleSystem *ps = [CCParticleExplosion node];
	[self addChild:ps z:12];
	ps.texture = [[CCTextureCache sharedTextureCache] addImage:@"stars.png"];
//	ps.blendAdditive = YES;
	ps.position = p;
	ps.life = 1.0f;
	ps.lifeVar = 1.0f;
	ps.totalParticles = 60.0f;
	ps.autoRemoveOnFinish = YES;
	[[SimpleAudioEngine sharedEngine] playEffect:@"collectStar.mp3"];
}

- (void)updateCamera {
//	NSLog(@"self.position = (%f, %f)",self.position.x,self.position.y);
	id move = [CCMoveTo actionWithDuration:2 position:ccpNeg(cameraOffset)];
	id ease = [CCEaseInOut actionWithAction:move rate:2];
	[self runAction:ease];
}

- (BOOL)dragHeroNearGrab:(Grab*)g {
	float dist = ccpDistance(dragHero.position, g.position);
	if(dist < snapDist) {
		return YES;
	}
	return NO;
}

- (void)scheduleRockAlert {
	float delay = (float)(arc4random()%100)/100.0f*7.0f+3.0f; // 3-10 seconds
	rockTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(showRockAlert) userInfo:nil repeats:NO];
}

- (void)showRockAlert {
	rockTimer = nil;
	if(!gameInProgress) return;
	if(-self.position.y >= levelHeight-sh) return;
	float padding = sw*128/768;
	float x = (float)(arc4random()%(int)(sw-padding*2))+padding;
	rockAlert.position = ccp(x, sh*31/32-self.position.y);
	id a1 = [CCFadeIn actionWithDuration:0.5f];
	id a2 = [CCFadeOut actionWithDuration:0.5f];
	id a3 = [CCCallFunc actionWithTarget:self selector:@selector(dropRock)];
	[rockAlert runAction:[CCSequence actions:a1,a2,a1,a2,a1,a2,a3,nil]];
}

- (void)dropRock {
//	if(-self.position.y < levelHeight-1024) {
		rock.position = ccp(rockAlert.position.x, levelHeight);
		rock.falling = YES;
		[rock runAction:[CCFadeIn actionWithDuration:0.5f]];
//	}
	[[SimpleAudioEngine sharedEngine] playEffect:@"dropRock.mp3"];
	[self scheduleRockAlert];
}

- (void)updateDragHeroPositionWithTouchLocation:(CGPoint)touchLocation {
	CGPoint levelLocation = ccpSub(touchLocation, self.position);
	float dist;
	
	dragHero.position = ccpAdd(levelLocation, dragOffset);
	
	CGPoint heroDelta = ccpSub(dragHero.position, dragOtherHero.position);
	dist = ccpLength(heroDelta);
	if(dist > ropeLength) {
		CGPoint dir = ccpNormalize(heroDelta);
		dragHero.position = ccpAdd(dragOtherHero.position, ccpMult(dir, ropeLength));
	}
	
	// collect stars
	for (Star *s in stars) {
		if(s.collected) continue;
		dist = ccpDistance(dragHero.position, s.position);
		if(dist < heroStarDist) {
			s.collected = YES;
			starsCollected++;
			[self updateStarsCollectedLabel];
			id a1 = [CCScaleTo actionWithDuration:0.5f scale:3.0f];
			id a2 = [CCFadeOut actionWithDuration:0.5f];
			[s runAction:[CCSpawn actions:a1,a2,nil]];
			[self sparkleAt:s.position];
			break;
		}
	}
	
	// snap feedback
	BOOL snapped = NO;
	for (Grab *g in grabs) {
		float dist = ccpDistance(dragHero.position, g.position);
		if(dist < snapDist) {
			float t = (snapDist - dist)/snapDist;
			snapFeedback.scale =  t*0.75f + 0.25f;
			snapFeedback.opacity = t*255.0f;
			snapFeedback.position = g.position;
			snapped = YES;
			break;
		}
	}
	if(!snapped && snapFeedback.opacity > 0) {
		snapFeedback.opacity = 0;
	}
}

- (void)updateStarsCollectedLabel {
	[starsCollectedLabel setString:[NSString stringWithFormat:@"%d/%d",starsCollected,starsTotal]];
}

- (void)updateUIPosition {
	float ny = sh-32-self.position.y;
	starIcon.position = ccp(starIcon.position.x,ny);
	starsCollectedLabel.position = ccp(starsCollectedLabel.position.x, ny);
	menuButton.position = ccp(menuButton.position.x,ny);
}

- (void)showPopupMenu {
	gameInProgress = NO;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game Paused" message:nil delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:@"Main Menu", nil];
	[alert show];
	[alert release];
	[[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[[SimpleAudioEngine sharedEngine] resumeBackgroundMusic];
	if(buttonIndex == 1) {
		// main menu
		[[CCDirector sharedDirector] pushScene:[Intro scene]];
	} else {
		if([self getChildByTag:kTagLabel]) {
			// level completed or failed, nop
		} else {
			gameInProgress = YES;
		}
	}
}

@end
