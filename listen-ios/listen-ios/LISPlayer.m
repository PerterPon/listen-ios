//
//  LISPlayer.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISPlayer.h"
#import "LISData.h"
#import <AVFoundation/AVFoundation.h>

#define SAMPLE_RATE 48000
#define BIT_RATE SAMPLE_RATE*16

@interface LISPlayer() {
    dispatch_queue_t addDataQueue;
    BOOL loaded;
}

@end

@implementation LISPlayer

static LISPlayer *player = nil;

+(instancetype) shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[self alloc] init];
        
//        LISData *data = [LISData shareInstance];
//        data.delegate = player;
    });
    
    return player;
}

-(void) initPlayer {
//    self.queuePlayer = [[LISQueuePlayer alloc] init];
//    [self.queuePlayer initQueue];
//    [self.queuePlayer play];
//    LISData *data = [LISData shareInstance];
//    [data initData];
}

- (void) pause {
    [self.queuePlayer pause];
    [[LISQueueData shareInstance] pause];
}

- (void) play {
    
}

- (void) resume {
    [self.queuePlayer resume];
    [[LISQueueData shareInstance] resume];
}

- (void) stop {
//    [self.queuePlayer stop]
}

-(void) startPlay {
    self.queuePlayer = [[LISQueuePlayer alloc] init];
    [self.queuePlayer initQueue];
    [self.queuePlayer play];
}

#pragma mark - lisRadioData delegate

-(void) onFirstDataReceived {
    [self startPlay];
}

-(void) onDataReceived {
    if (NO == self.queuePlayer.playying) {
        [self.queuePlayer refillBuffes];
        [self.queuePlayer play];
    }
}

#pragma mark - lisData delegate

-(void) dataDidReceiveFirstFregment {
    LISData *data = [LISData shareInstance];
    NSError *error;
}

-(void) dataDidReceiveMediaFregmentWithNumber:(int)number {
    LISData *data = [LISData shareInstance];
    if (1 == number) {
        [self startPlay];
    } else if (NO == self.queuePlayer.playying) {
        [self.queuePlayer refillBuffes];
        [self.queuePlayer play];
    }
}

@end
