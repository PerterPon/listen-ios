//
//  LISPlayer.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISPlayer.h"
//#import "LISData.h"
#import "LISRadioDataNew.h"
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
    NSLog(@"pause");
    [self.queuePlayer pause];
    NSLog(@"1111");
    [[LISRadioDataNew shareInstance] pause];
    NSLog(@"2222");
    self.playying = NO;
}

- (void) play {
    self.playying = YES;
}

- (void) resume {
    NSLog(@"resume");
    [self.queuePlayer resume];
    [[LISRadioDataNew shareInstance] resume];
    self.playying = YES;
}

- (void) stop {
    [[LISRadioDataNew shareInstance] stop];
}

-(void) startPlay {
    self.queuePlayer = [[LISQueuePlayer alloc] init];
    [self.queuePlayer initQueue];
    [self.queuePlayer play];
    self.playying = YES;
}

#pragma mark - lisRadioData delegate

- (void) onFirstDataReceived {
    if (nil == self.queuePlayer) {
        [self startPlay];
    } else {
        [self onDataReceived];
    }
}

- (void) onDataReceived {
//    NSLog(self.queuePlayer.playying);
    if (NO == self.queuePlayer.playying) {
        [self.queuePlayer refillBuffes];
        [self.queuePlayer play];
    }
}

#pragma mark - lisData delegate

-(void) dataDidReceiveFirstFregment {
    LISRadioDataNew *data = [LISRadioDataNew shareInstance];
    NSError *error;
}

-(void) dataDidReceiveMediaFregmentWithNumber:(int)number {
    LISRadioDataNew *data = [LISRadioDataNew shareInstance];
    if (1 == number) {
        [self startPlay];
    } else if (NO == self.queuePlayer.playying) {
        [self.queuePlayer refillBuffes];
        [self.queuePlayer play];
    }
}

@end
