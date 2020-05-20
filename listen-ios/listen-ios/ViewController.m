//
//  ViewController.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "ViewController.h"
#import "LISPlayer.h"

@interface ViewController ()
{
    UIButton *button;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(onPlay) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"pause" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.frame = CGRectMake(150, 400, 160, 40);
    self -> button = button;
    [self.view addSubview:button];
}

- (void) onPlay {
    LISPlayer *player = [LISPlayer shareInstance];
    BOOL playying = player.playying;
    if (YES == playying) {
        [player pause];
        [button setTitle:@"play" forState:UIControlStateNormal];
    } else {
        [player resume];
        [button setTitle:@"pause" forState:UIControlStateNormal];
    }
}

@end
