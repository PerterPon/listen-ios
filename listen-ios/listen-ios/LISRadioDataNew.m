//
//  LISRadioDataNew.m
//  listen-ios
//
//  Created by PerterPon on 2020/3/16.
//  Copyright © 2020 PerterPon. All rights reserved.
//

#import "LISRadioDataNew.h"
#import "LISEtc.h"
#import <NSString+MD5.h>

@interface LISRadioDataNew()
{
    BOOL queuing;
    int receiveTimes;
    NSString *radioName;
    int doneFregmentId;
    int currentFregmentId;
    int baselineFregmentId;
    NSMutableDictionary *queueRequestMap;
    NSMutableDictionary *queueDataMap;
}

@end


@implementation LISRadioDataNew

static LISRadioDataNew *radioData;

+(instancetype) shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        radioData = [[self alloc] init];
    });
    
    return radioData;
}

-(void) initData {
    self.data = [[NSMutableData alloc] init];
    queuing = NO;
    receiveTimes = 0;
    doneFregmentId = 0;
    baselineFregmentId = 0;
    queueDataMap = [[NSMutableDictionary alloc] init];
    queueRequestMap = [[NSMutableDictionary alloc] init];
}

-(void) startWith:(NSString *)name {
    if (YES == queuing) {
        [self stop];
    }
    radioName = name;
    [self.data resetBytesInRange:NSMakeRange(0, [self.data length])];
    [self.data setLength:0];

    LISEtc *etc = [LISEtc shareInstance];
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timestamp = round([date timeIntervalSince1970]*1000);
    
    NSString *sign = [[NSString stringWithFormat:@"%@%f", etc.salt, timestamp] MD5Digest];
    NSString *urlString = [NSString stringWithFormat:@"%@:%d/radio/register?timestamp=%f&sign=%@&name=%@", etc.httpsDomain, etc.port, timestamp, sign, name];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    receiveTimes = 0;
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 6.0;
    sessionConfig.timeoutIntervalForResource = 6.0;
    
    NSURLSessionDataTask *task = [session
                                  dataTaskWithRequest:request
                                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                      if (nil != error) {
                                          NSTimer *timer = [NSTimer timerWithTimeInterval:3.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
                                              [self startWith:name];
                                          }];
                                          self.timer = timer;
                                          [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
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
                                      self.radioInfo = currentRadioInfo;
                                      [self startQueue];
                                  }];
    [task resume];
}

- (void) pause {
    
}

- (void) resume {
    
}

- (void) stop {
    
}

- (void) loadMuteData {
    
}

- (void) startQueue {
    
}

- (void) startTimeline {
    self -> currentFregmentId = [self generateCurrentFregmentId];

    // 1. clear current data
    // 1.1 check if last data can be used
    if (nil != self -> queueDataMap) {
        NSString *latestId = [NSString stringWithFormat:@"%d", self -> currentFregmentId - 2];
        NSString *lastId = [NSString stringWithFormat:@"%d", self -> currentFregmentId - 1];
        NSMutableDictionary *latestData = self -> queueDataMap[latestId];
        NSMutableDictionary *lastData = self -> queueDataMap[lastId];
        self -> queueDataMap = [[NSMutableDictionary alloc] init];
        if (nil != latestData) {
            [self -> queueDataMap setObject:latestData forKey:latestId];
            [self -> queueDataMap setObject:lastData forKey:lastId];
        }
    } else {
        self -> queueDataMap = [[NSMutableDictionary alloc] init];
    }

    self -> queueRequestMap = [[NSMutableDictionary alloc] init];
    if (nil != self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.data = [[NSMutableData alloc] init];
    
    // 2. load start fregment
    [self loadStartFregment:^{
        // 3. start first play
        [self assemblyDataWith:self -> currentFregmentId - 2];
        [self assemblyDataWith:self -> currentFregmentId - 1];
        [self.delegate onFirstDataReceived];
        // 4. start nature clock to schdule the timeline.
        [self startNatureClock];
    } :^{
        // if failed, recall ths function again.
        NSLog(@"load start fegment failed! restart after 5 sec!");
        [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self startTimeline];
        }];
    }];
}

- (void) startNatureClock {
    NSNumber *duration = self.radioInfo.fregmentDuration;
    // for the first time
    [self ticktock];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:[duration doubleValue] repeats:YES block:^(NSTimer * _Nonnull timer) {
        self -> currentFregmentId = [self generateCurrentFregmentId];
        [self ticktock];
    }];
}

- (void) ticktock {
    int requestFregmentId = self -> currentFregmentId;
    NSDate *startTime = [NSDate date];
    [self loadFregmentWith: requestFregmentId :^(NSData *data) {
        NSDate *endTime = [NSDate date];
        int nowFregmentId = self -> currentFregmentId;
        // 1. first of all, this reqest is success, so we need insert data for this request.
        NSString *stringId = [NSString stringWithFormat:@"%id", requestFregmentId];
        NSDictionary *dataMap = @{
            @"data": data,
            @"startTime": startTime,
            @"endTime": endTime,
            @"complete": @0
        };
        // 1.1 insert data
        [self -> queueDataMap setObject: dataMap forKey:stringId];
        // 1.2 delete expired data
        NSString *expiredId = [NSString stringWithFormat:@"%d", requestFregmentId - 3];
        [self -> queueDataMap removeObjectForKey:expiredId];

        // 2. check the data sequence, if need abandon some data.
        BOOL res = [self checkIfCanAssemblyData:nowFregmentId :requestFregmentId];
        // 2.1 no data assembly, need check sequence
        if (false == res && nowFregmentId - requestFregmentId >= 3) {
            // all data can not be used, we need restart timeline.
            [self startTimeline];
        } else {
            // 3. notify the player to play data.
            [self.delegate onDataReceived];
        }
    } :^{
        
    }];
}

- (BOOL) checkIfCanAssemblyData: (int)nowFregmentId :(int)requestFregmentId {
    // check last1 and last2 sequence is ready
    BOOL result = NO;
    if (requestFregmentId == nowFregmentId) {
        NSMutableDictionary *last1Data = [self -> queueDataMap objectForKey:[NSString stringWithFormat:@"%d", requestFregmentId - 1]];
        NSMutableDictionary *last2Data = [self -> queueDataMap objectForKey:[NSString stringWithFormat:@"%d", requestFregmentId - 2]];
        // best situation, no data delay.
        if (nil != last1Data && nil != last2Data){
            [self assemblyDataWith:requestFregmentId];
            [self -> queueDataMap removeObjectForKey:[NSString stringWithFormat:@"%d", requestFregmentId - 2]];
            result = YES;
        } else {
            // there is some data not ready, just return no.
            result = NO;
        }
    } else if (requestFregmentId == nowFregmentId - 1) {
        NSMutableDictionary *last1Data = [self -> queueDataMap objectForKey:[NSString stringWithFormat:@"%d", requestFregmentId - 1]];
    }
    return result;
}

- (void) assemblyDataWith: (int)fregmentId {
    NSString *stringId = [NSString stringWithFormat:@"%d", fregmentId];
    NSMutableDictionary *data = [self -> queueDataMap objectForKey:stringId];
    if (data) {
        [data setObject:@1 forKey:@"complete"];
        [self.data appendData: [data objectForKey:@"data"]];
    }
}

- (void) loadStartFregment: (void (^)(void))successHandler :(void (^)(void))failedHandler {
    int currentFregmentId = self -> currentFregmentId;
    // 1. load the N - 2 and N - 1
    NSDate *date = [NSDate date];
    __block NSMutableDictionary *queueData1 = [[NSMutableDictionary alloc] init];
    __block NSMutableDictionary *queueData2 = [[NSMutableDictionary alloc] init];
    queueData1[@"startTime"] = date;
    queueData1[@"complete"] = 0;
    queueData2[@"startTime"] = date;
    queueData2[@"complete"] = 0;
    NSString *latestId = [NSString stringWithFormat:@"%d", currentFregmentId - 2];
    NSMutableDictionary *latestData = [self -> queueDataMap objectForKey:latestId];
    if (nil == latestData) {
        [self loadFregmentWith:currentFregmentId - 2 :^(NSData *data) {
            // if the current fregmentId is later then the first time, just ignore it;
            if (self -> currentFregmentId == currentFregmentId) {
                NSString *stringId = [NSString stringWithFormat:@"%d", currentFregmentId - 2];
                queueData2[@"data"] = data;
                queueData2[@"endTime"] = [NSDate date];

                self -> queueDataMap[stringId] = queueData2;
                // check if another request is finished
                if (2 == [self -> queueDataMap allKeys].count) {
                    successHandler();
                }
            }
        } :failedHandler];
    }
    
    NSString *lastId = [NSString stringWithFormat:@"%d", currentFregmentId - 1];
    NSMutableDictionary *lastData = [self -> queueDataMap objectForKey:lastId];
    if (nil == lastData) {
        [self loadFregmentWith:currentFregmentId - 1 :^(NSData *data) {
            // if the current fregmentId is later then the first time, just ignore it;
            if (self -> currentFregmentId == currentFregmentId) {
                NSString *stringId = [NSString stringWithFormat:@"%d", currentFregmentId - 1];
                queueData1[@"data"] = data;
                queueData1[@"endTime"] = [NSDate date];
                self -> queueDataMap[stringId] = queueData1;
                // check if another request is finished
                if (2 == [self -> queueDataMap allKeys].count) {
                    successHandler();
                }
            }
        } :failedHandler];
    }
    
    // if all data is already ready, just call the callback.
    if (2 == [self -> queueDataMap allKeys].count) {
        successHandler();
    }
}

- (NSURLSessionDataTask *) loadFregmentWith: (int)fregmentId :(void (^)(NSData *data))successHandler :(void (^)(void))failedHander {
    NSLog(@"load fregment: %d", fregmentId);
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval nowTime = [date timeIntervalSince1970];
    LISEtc *etc = [LISEtc shareInstance];
    NSString *signedMd5Id = [[NSString stringWithFormat:@"%@_%d", etc.salt, fregmentId] MD5Digest];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@.mp3", etc.cdnDomain, self.radioInfo.baseUrl, signedMd5Id];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 7;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            NSLog(@"load with error: %d", fregmentId);
            failedHander();
            return;
        }
        if (self -> doneFregmentId >= fregmentId) {
            return;
        }
        successHandler(data);

        NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval loadDone = [date timeIntervalSince1970];
        NSLog(@"done: %d, time: %f", fregmentId, loadDone - nowTime);
        
    }];
    [task resume];
    return task;
}

- (int) generateCurrentFregmentId {
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time = [date timeIntervalSince1970];
    int fregmentId = (int)((double)time / [self.radioInfo.duration doubleValue]);
    return fregmentId - 1;
}

@end
