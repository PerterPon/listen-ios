//
//  AppDelegate.h
//  testgps
//
//  Created by PerterPon on 2020/3/24.
//  Copyright © 2020 PerterPon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

