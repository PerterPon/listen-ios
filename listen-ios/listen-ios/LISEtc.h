//
//  LISEtc.h
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LISEtc : NSObject
    @property (nonatomic, assign) NSString *domain;
    @property (nonatomic, assign) int port;
    @property (nonatomic, assign) NSString *salt;
    @property (nonatomic, assign) NSString *cdnDomain;

    +(instancetype) shareInstance;
    
    -(void) initConfig;

@end

NS_ASSUME_NONNULL_END
