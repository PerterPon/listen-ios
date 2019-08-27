//
//  LISPlayer.h
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LISQueuePlayer.h"
//#import "LISData.h"
#import "LISRadioData.h"
#import "LISQueueData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LISPlayerDelegate <NSObject>

-(void) playDidFinishPlayDataWith: (NSNumber *)size;

@end

@interface LISPlayer : NSObject <LISQueueDataDelegate>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, weak) id <LISPlayerDelegate> delegate;
@property (nonatomic, strong) LISQueuePlayer *queuePlayer;

+(instancetype) shareInstance;

-(void) initPlayer;

-(void) play;

-(void) pause;

-(void) resume;

-(void) stop;

@end

NS_ASSUME_NONNULL_END
