//
//  LISQueueData.h
//  listen-ios
//
//  Created by PerterPon on 2019/8/24.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LISQueueDataDelegate <NSObject>

-(void) onFirstDataReceived;
-(void) onDataReceived;

@end

@interface LISQueueData : NSObject

+(instancetype) shareInstance;

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSTimer *retryTimer;
@property (nonatomic, strong) dispatch_queue_t timeLineQueue;
@property (nonatomic, strong) NSTimer *timeLineTimer;
@property (nonatomic, strong) id<LISQueueDataDelegate> delegate;

-(void) startWith: (NSString *)name duration: (NSNumber *)duration;

-(void) pause;

-(void) resume;

-(void) loadMuteData;

@end

NS_ASSUME_NONNULL_END
