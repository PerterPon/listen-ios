//
//  LISRadioDataNew.h
//  listen-ios
//
//  Created by PerterPon on 2020/3/16.
//  Copyright © 2020 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct RadioInfo {
    NSString *duration;
    NSString *timescale;
    NSString *codecs;
    NSString *mimeType;
    NSString *sampleRate;
    NSString *baseUrl;
    NSNumber *fregmentDuration;
};

@protocol LISRadioDataDelegate <NSObject>

-(void) onFirstDataReceived;
-(void) onDataReceived;

@end

@interface LISRadioDataNew : NSObject

+(instancetype) shareInstance;

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, assign) struct RadioInfo radioInfo;
@property (nonatomic, weak) id <LISRadioDataDelegate> delegate;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSTimer *mediaTimer;

-(void) initData;

-(void) startWith: (NSString *)name;

-(void) pause;

-(void) resume;

-(void) stop;

-(void) loadMuteData;

@end

NS_ASSUME_NONNULL_END
