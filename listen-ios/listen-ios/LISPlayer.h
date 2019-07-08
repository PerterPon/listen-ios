//
//  LISPlayer.h
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LISData.h"

NS_ASSUME_NONNULL_BEGIN

@interface LISPlayer : NSObject <LISDataProtocol>
    
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) AVPlayer *player;

+(instancetype) shareInstance;

-(void) initPlayer;

-(void) play;

-(void) pause;

-(void) resume;

-(void) stop;

@end

NS_ASSUME_NONNULL_END
