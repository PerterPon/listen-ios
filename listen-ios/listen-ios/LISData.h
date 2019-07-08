//
//  LISData.h
//  listen-ios
//
//  Created by PerterPon on 2019/7/8.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LISDataProtocol <NSObject>

-(void) dataDidReceiveFirstFregment;
-(void) dataDidReceiveMediaFregmentWithNumber:(int) number;

@end

@interface LISData : NSObject

@property (nonatomic, strong, nullable) NSString *baseUrl;
@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSMutableData *data;
@property (nonatomic, weak) id <LISDataProtocol> delegate;
@property (nonatomic) int mediaFregmentCount;
@property (nonatomic, strong) NSMutableArray *requestQueue;

@property (nonatomic) BOOL loading;
@property (nonatomic, strong, nullable) NSData *firstFregment;

+(instancetype) shareInstance;

-(void) initData;
-(void) onFirstFregment:(NSString *)fregmentName;
-(void) onMediaFregment:(NSString *)fregmentId;

-(void) clearData;
@end

NS_ASSUME_NONNULL_END
