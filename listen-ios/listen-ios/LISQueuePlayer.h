//
//  LISQueuePlayer.h
//  listen-ios
//
//  Created by PerterPon on 2019/8/4.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LISQueuePlayer : NSObject

@property (nonatomic) BOOL playying;
@property (nonatomic, retain) NSTimer *timer;

- (void) initQueue;

- (void) play;

- (void) pause;

- (void) resume;

- (BOOL) isStopped;

- (void) refillBuffes;

@end

NS_ASSUME_NONNULL_END
