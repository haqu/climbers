/*
 * Climbers
 * https://github.com/haqu/climbers
 *
 * Copyright (c) 2011 Sergey Tikhonov
 *
 */

#import "Intro.h"
#import "Game.h"
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

@interface Intro()
- (void)tapDownAt:(CGPoint)location;
- (void)tapUpAt:(CGPoint)location;
@end

@implementation Intro

+ (CCScene*)scene {
	CCScene *scene = [CCScene node];
	[scene addChild:[Intro node]];
	return scene;
}

- (id)init {
	if((self = [super init])) {
#ifdef IOS
		self.isTouchEnabled = YES;
#else
		self.isMouseEnabled = YES;
#endif

		CGSize ss = [[CCDirector sharedDirector] winSize];
		float sw = ss.width;
		float sh = ss.height;
		
		CCSprite *wall = [CCSprite spriteWithFile:@"wall.png" rect:CGRectMake(0, 0, sw, sh/2)];
		wall.position = ccp(sw/2, sh/4);
		[self addChild:wall];
		ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
		[wall.texture setTexParameters:&tp];

		// sprite sheet
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sprites.plist"];
		CCSpriteBatchNode *batch = [[CCSpriteBatchNode alloc] initWithFile:@"sprites.png" capacity:50];
		[self addChild:batch];
		
		// sprites
		CCSprite *sprite;

		sprite = [CCSprite spriteWithSpriteFrameName:@"bottom.png"];
		sprite.position = ccp(sw/2, sh/32);
		[batch addChild:sprite];
		
		sprite = [CCSprite spriteWithSpriteFrameName:@"top.png"];
		sprite.position = ccp(sw/2, sh/2);
		[batch addChild:sprite];
		
		sprite = [CCSprite spriteWithSpriteFrameName:@"gameTitle.png"];
		sprite.position = ccp(sw/2, sh*7/8);
		[batch addChild:sprite];

		sprite = [CCSprite spriteWithSpriteFrameName:@"moreGamesButton.png"];
		sprite.position = ccp(sw/4, sh/2);
		sprite.opacity = 0;
		id a1 = [CCDelayTime actionWithDuration:0.2f];
		id a2 = [CCFadeIn actionWithDuration:0.4f];
		[sprite runAction:[CCSequence actions:a1,a2,nil]];
		[batch addChild:sprite];
		moreGamesButton = [sprite retain];
		
		sprite = [CCSprite spriteWithSpriteFrameName:@"playButton.png"];
		sprite.position = ccp(sw/2, sh/2);
		sprite.opacity = 0;
		[sprite runAction:[CCFadeIn actionWithDuration:0.2f]];
		[batch addChild:sprite];
		playButton = [sprite retain];

		sprite = [CCSprite spriteWithSpriteFrameName:@"gameSourcesButton.png"];
		sprite.position = ccp(sw*3/4, sh/2);
		sprite.opacity = 0;
		a1 = [CCDelayTime actionWithDuration:0.2f];
		a2 = [CCFadeIn actionWithDuration:0.4f];
		[sprite runAction:[CCSequence actions:a1,a2,nil]];
		[batch addChild:sprite];
		gameSourcesButton = [sprite retain];
		
		sprite = [CCSprite spriteWithSpriteFrameName:@"gpcLogo.png"];
		sprite.position = ccp(sw*5/48, sh*11.7f/256);
		sprite.opacity = 0;
		a1 = [CCDelayTime actionWithDuration:0.6f];
		a2 = [CCFadeIn actionWithDuration:0.4f];
		[sprite runAction:[CCSequence actions:a1,a2,nil]];
		[batch addChild:sprite];

		sprite = [CCSprite spriteWithSpriteFrameName:@"cocos2dLogo.png"];
		sprite.position = ccp(sw*43/48, sh*14.2f/256);
		sprite.opacity = 0;
		a1 = [CCDelayTime actionWithDuration:0.6f];
		a2 = [CCFadeIn actionWithDuration:0.4f];
		[sprite runAction:[CCSequence actions:a1,a2,nil]];
		[batch addChild:sprite];

		// labels
		CCLabelTTF *label;

		float fontSize = 12.0f;
		if(IS_IPHONE) fontSize = 6.0f;
		
		label = [CCLabelTTF labelWithString:@"Created by @haqu for Game Prototype Challenge using Cocos2D." fontName:@"Verdana-Bold" fontSize:fontSize];
		label.position = ccp(sw/2, sh*5/256);
		label.opacity = 0;
		a1 = [CCDelayTime actionWithDuration:0.6f];
		a2 = [CCFadeIn actionWithDuration:0.4f];
		[label runAction:[CCSequence actions:a1,a2,nil]];
		[self addChild:label];

		[[SimpleAudioEngine sharedEngine] preloadEffect:@"click.caf"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"grab.caf"];
		
		[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"intro.mp3"];
	}
	return self;
}

- (void)dealloc {
	[playButton release];
	[moreGamesButton release];
	[gameSourcesButton release];
	[super dealloc];
}

- (void)registerWithTouchDispatcher {
#ifdef IOS
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
#else
	[[CCEventDispatcher sharedDispatcher] addMouseDelegate:self priority:0];
#endif
}

- (void)tapDownAt:(CGPoint)location {
	NSLog(@"tapDown");
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	float sw = screenSize.width;
	float sh = screenSize.height;
	CGRect rect;
	
	// play button
	rect = CGRectMake(sw/2-64, sh/2-64, 128, 128);
	if(CGRectContainsPoint(rect, location)) {
		playButton.scale = 0.95f;
		[[SimpleAudioEngine sharedEngine] playEffect:@"click.caf"];
	}

	// more games button
	rect = CGRectMake(sw/4-32, sh/2-32, 64, 64);
	if(CGRectContainsPoint(rect, location)) {
		moreGamesButton.scale = 0.95f;
		[[SimpleAudioEngine sharedEngine] playEffect:@"click.caf"];
	}

	// game sources button
	rect = CGRectMake(sw*3/4-32, sh/2-32, 64, 64);
	if(CGRectContainsPoint(rect, location)) {
		gameSourcesButton.scale = 0.95f;
		[[SimpleAudioEngine sharedEngine] playEffect:@"click.caf"];
	}
}

- (void)tapUpAt:(CGPoint)location {
	NSLog(@"tapUp");
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	float sw = screenSize.width;
	float sh = screenSize.height;
	CGRect rect;

	playButton.scale = 1.0f;
	moreGamesButton.scale = 1.0f;
	gameSourcesButton.scale = 1.0f;
	
	// play button
	rect = CGRectMake(sw/2-64, sh/2-64, 128, 128);
	if(CGRectContainsPoint(rect, location)) {
		[[CCDirector sharedDirector] pushScene:[Game scene]];
	}
	
	// more games button
	rect = CGRectMake(sw/4-32, sh/2-32, 64, 64);
	if(CGRectContainsPoint(rect, location)) {
		NSString *urlString = @"itms-apps://itunes.com/apps/iplayfulinc";
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
	}
	
	// game sources button
	rect = CGRectMake(sw*3/4-32, sh/2-32, 64, 64);
	if(CGRectContainsPoint(rect, location)) {
		NSString *urlString = @"https://github.com/haqu/climbers";
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
	}
}

#ifdef IOS
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	[self tapDownAt:location];
	return YES;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
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

- (BOOL)ccMouseUp:(NSEvent *)event {
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	[self tapUpAt:location];
	return YES;
}

#endif // IOS or MAC

@end
