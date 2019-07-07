//
//  LISPlayer.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISPlayer.h"

dispatch_queue_t queue;

@implementation LISPlayer
    
    static LISPlayer *player = nil;
    
    +(instancetype) shareInstance {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            player = [[self alloc] init];
        });
        queue = dispatch_queue_create("pon.listen.player", DISPATCH_QUEUE_SERIAL);
        
        return player;
    }
    
    -(void) initPlayer {
        
    }
    
    -(void) onFirstFregment:(NSString *)fregmentName {
        dispatch_async(queue, ^{
            NSLog(@"first fregment %@", fregmentName);
        });
    }
    
    -(void) onMediaFregment:(NSString *)fregmentId {
        dispatch_async(queue, ^{
            NSLog(@"media fregment %@", fregmentId);
        });
    }

@end
