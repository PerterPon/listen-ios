//
//  LISQueueData.m
//  listen-ios
//
//  Created by PerterPon on 2019/8/24.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISQueueData.h"
#import "LISEtc.h"
#import <NSString+MD5.h>

struct RadioInfo {
    NSString *duration;
    NSString *timescale;
    NSString *codecs;
    NSString *mimeType;
    NSString *sampleRate;
    NSString *baseUrl;
    NSNumber *fregmentDuration;
};

@interface LISQueueData()
{
    NSNumber *duration;
    NSString *name;
    NSMutableArray *fregemntQueue;
    int timelineFregmentId;
    int doneFregmentId;
    struct RadioInfo radioInfo;
    NSURLSessionTask *currentTask;
}
@end

static LISQueueData *radioData;

@implementation LISQueueData

+(instancetype) shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        radioData = [[self alloc] init];
    });
    
    return radioData;
}

-(void) startWith:(NSString *)name duration:(NSNumber *)duration {
    [self stopTimeLine];
    self -> fregemntQueue = [[NSMutableArray alloc] init];
    doneFregmentId = 0;
    self -> name = name;
    self.data = [[NSMutableData alloc] init];
    self.timeLineQueue = dispatch_queue_create("com.pon.data.timer", DISPATCH_QUEUE_SERIAL);
    [self registerChannel:name :^(struct RadioInfo radioInfo) {
        NSLog(@"register %@ success", name);
        self -> radioInfo = radioInfo;
        [self startTimeline];
        int fregmentId = [self generateNowFregmentId];
        self -> timelineFregmentId = fregmentId;
        [self -> fregemntQueue addObject:[NSNumber numberWithInt:fregmentId - 1]];
        [self -> fregemntQueue addObject:[NSNumber numberWithInt:fregmentId]];
        [self loadTimeLineMediaData];
    }];
}

-(void) loadMuteData {
    NSString *muteFile = [[NSBundle mainBundle] pathForResource:@"mute" ofType:@"mp3"];
    NSData *muteData = [NSData dataWithContentsOfFile:muteFile];
    [self.data appendData:muteData];
}

-(void) pause {
    [self stopTimeLine];
    [self -> fregemntQueue removeAllObjects];
    self.data = [[NSMutableData alloc] init];
}

- (void) resume {
    [self startTimeline];
    int fregmentId = [self generateNowFregmentId];
    self -> timelineFregmentId = fregmentId;
    [self -> fregemntQueue addObject:[NSNumber numberWithInt:fregmentId - 1]];
    [self loadTimeLineMediaData];
}

-(void) loadTimeLineMediaData {
    if (0 >= self -> fregemntQueue.count || nil != self -> currentTask) {
        NSLog(@"first return, count: %lu", (unsigned long)self -> fregemntQueue.count);
        return;
    }
    __block NSNumber *fregment = [self -> fregemntQueue objectAtIndex:0];
    int fregmentId = [fregment intValue];
    if (fregmentId <= self -> doneFregmentId) {
        [self -> fregemntQueue removeObject:fregment];
        [self loadTimeLineMediaData];
        NSLog(@"second return, done: %d, f: %d", self -> doneFregmentId, fregmentId);
        return;
    }
    
    if (1 == self -> fregemntQueue.count && 1 < fregmentId - self -> doneFregmentId) {
        [self -> fregemntQueue insertObject:[NSNumber numberWithInt:fregmentId - 1] atIndex:0];
        [self loadTimeLineMediaData];
        return;
    }

    [self loadMediaDataWith:fregmentId success:^(NSData *data) {
        [self.data appendData:data];

        if (0 == self -> doneFregmentId) {
            [self.delegate onFirstDataReceived];
        } else {
            [self.delegate onDataReceived];
        }

        self -> doneFregmentId = fregmentId;
        [self -> fregemntQueue removeObject:fregment];
        if (0 < self -> fregemntQueue.count) {
            [self loadTimeLineMediaData];
        }
        
    } failed:^{
        NSTimer *timer = [NSTimer timerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
            if (YES == [self -> fregemntQueue containsObject:fregment]) {
                NSLog(@"retry");
                [self loadTimeLineMediaData];
            }
        }];
        self.retryTimer = timer;
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }];
}

-(void) registerChannel: (NSString *)name :(void(^)(struct RadioInfo radioInfo))success {
    LISEtc *etc = [LISEtc shareInstance];
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timestamp = round([date timeIntervalSince1970]*1000);
    
    NSString *sign = [[NSString stringWithFormat:@"%@%f", etc.salt, timestamp] MD5Digest];
    NSString *urlString = [NSString stringWithFormat:@"%@:%d/radio/register?timestamp=%f&sign=%@&name=%@", etc.httpsDomain, etc.port, timestamp, sign, name];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            NSTimer *timer = [NSTimer timerWithTimeInterval:3.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
                [self registerChannel:name :success];
            }];
            
            self.retryTimer = timer;
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (nil == dict) {
            return;
        }
        NSDictionary *radioData = dict[@"data"];
        struct RadioInfo currentRadioInfo;
        currentRadioInfo.codecs = radioData[@"codecs"];
        currentRadioInfo.duration = radioData[@"duration"];
        currentRadioInfo.timescale = radioData[@"timescale"];
        currentRadioInfo.mimeType = radioData[@"mimeType"];
        currentRadioInfo.sampleRate = radioData[@"sampleRate"];
        currentRadioInfo.baseUrl = radioData[@"baseUrl"];
        
        float timescale = [currentRadioInfo.timescale floatValue];
        float duration = [currentRadioInfo.duration floatValue];
        float fregmentDuration = duration / timescale;
        currentRadioInfo.fregmentDuration = [NSNumber numberWithFloat:fregmentDuration];
        dispatch_async(dispatch_get_main_queue(), ^{
            success(currentRadioInfo);
        });
    }];
    
    [task resume];
}

-(void) loadMediaDataWith: (int)fregmentId success:(void(^)(NSData * data))success failed:(void(^)(void))failed {
    LISEtc *etc = [LISEtc shareInstance];
    NSString *signedMd5Id = [[NSString stringWithFormat:@"%@_%d", etc.salt, fregmentId] MD5Digest];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@.mp3", etc.cdnDomain, self -> radioInfo.baseUrl, signedMd5Id];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 6;
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval nowTime = [date timeIntervalSince1970];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        self -> currentTask = nil;
        if (nil != error) {
            dispatch_async(dispatch_get_main_queue(), failed);
            return;
        }
        NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval loadDone = [date timeIntervalSince1970];
        NSLog(@"done: %d, time: %f", fregmentId, loadDone - nowTime);
        dispatch_async(dispatch_get_main_queue(), ^{
            success(data);
        });
    }];
    self -> currentTask = task;
    [task resume];
}

-(void) startTimeline {
    NSNumber *duration = radioInfo.fregmentDuration;
    NSTimer *timer = [NSTimer
                      timerWithTimeInterval:[duration doubleValue]
                      repeats:YES block:^(NSTimer * _Nonnull timer) {
                          int fregment = ++self -> timelineFregmentId;
                          [self -> fregemntQueue addObject:[NSNumber numberWithInt:fregment]];
                          if(3 <= self -> fregemntQueue.count) {
                              [self -> fregemntQueue removeObjectAtIndex:0];
                          }
                          NSLog(@"---------------- %lu", self.data.length);
                          NSLog(@"timeline add: %d", fregment);
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self loadTimeLineMediaData];
                          });
                      }];
    self.timeLineTimer = timer;
    NSRunLoop *loop = [NSRunLoop mainRunLoop];
    [loop addTimer:self.timeLineTimer forMode:NSDefaultRunLoopMode];
}

-(int) generateNowFregmentId {
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timestamp = floor([date timeIntervalSince1970]);
    NSNumber *duration = radioInfo.fregmentDuration;
    int fregmentId = (int)((double)timestamp / [duration doubleValue]) - 1;
    return fregmentId;
}

-(void) stopTimeLine {
    if (self.timeLineTimer) {
        [self.timeLineTimer invalidate];
    }
}

@end
