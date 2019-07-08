//
//  LISPlayer.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISPlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation LISPlayer

static LISPlayer *player = nil;

+(instancetype) shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[self alloc] init];
        LISData *data = [LISData shareInstance];
        data.delegate = player;
    });
    
    return player;
}

-(void) initPlayer {
    LISData *data = [LISData shareInstance];
    [data initData];
}

-(void) play {
    
}

-(void) pause {
    
}

-(void) resume {
    
}

-(void) stop {
    
}

#pragma mark - lisData delegate

-(void) dataDidReceiveFirstFregment {
    
}

-(void) dataDidReceiveMediaFregmentWithNumber:(int)number {
    LISData *data = [LISData shareInstance];
    NSLog(@"did receive data with times: %d, length: %lu", number, (unsigned long)data.data.length);
    if (2 <= number) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
    }
}

@end
