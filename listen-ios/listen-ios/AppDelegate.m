//
//  AppDelegate.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "AppDelegate.h"
#import "LISEtc.h"
#import "LISPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "DCLog/DCLog.h"
#import <MediaPlayer/MediaPlayer.h>
//#import "LISQueueData.h"
#import "LISRadioDataNew.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    [self initApp];
    [DCLog setLogViewEnabled:NO];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    NSMutableDictionary *songDict = [NSMutableDictionary dictionary];
    
    // 音频名字
    [songDict setObject:@"bbcWorldService"  forKey:MPMediaItemPropertyTitle];
    
    // 歌手
    [songDict setObject:@"bbc"  forKey:MPMediaItemPropertyArtist];
    
    // 歌曲的总时间
    [songDict setObject:@(9999999999) forKeyedSubscript:MPMediaItemPropertyPlaybackDuration];
    
    // 当前时间
    [songDict setObject:@(1) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    // 播放速率
    [songDict setObject:@(1.0) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    // 设置控制中心歌曲信息
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songDict];
    
    [self createRemoteCommandCenter];
    return YES;
}

- (void)initApp {
    [[LISEtc shareInstance] initConfig];
//    [[LISConnection shareInstance] initConnection];
//    [LISConnection shareInstance].channelName = @"bbcWorldService";

    [[LISPlayer shareInstance] initPlayer];
//    [[LISRadioData shareInstance] initData];
//    [LISRadioData shareInstance].delegate = [LISPlayer shareInstance];
//    [[LISRadioData shareInstance] startWith:@"bbcWorldService"];
//    [[LISData shareInstance] initData];
//    [LISData shareInstance].delegate = [LISPlayer shareInstance];

    LISRadioDataNew *queueDataNew = [[LISRadioDataNew shareInstance] init];
    queueDataNew.delegate = [LISPlayer shareInstance];
    [queueDataNew startWith:@"bbcWorldService"];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    UIApplication*  app = [UIApplication sharedApplication];
    self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"listen_ios"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

- (void) remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPause:
                [[LISPlayer shareInstance] pause];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [[LISPlayer shareInstance] resume];
            default:
                break;
        }
//        NSLog(@"%ld",event.subtype);
//        if (event.subtype == UIEventSubtype.)
        
    }
}

- (void)createRemoteCommandCenter{
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        [[LISPlayer shareInstance] pause];
//        [self.player pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        [self.player play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    //    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
    //        NSLog(@"上一首");
    //        return MPRemoteCommandHandlerStatusSuccess;
    //    }];
    
//    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        NSLog(@"下一首");
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
    
    
}

@end
