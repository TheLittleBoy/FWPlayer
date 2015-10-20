//
//  FWSwipePlayerViewController.m
//  FWDraggableSwipePlayer
//
//  Created by Filly Wang on 20/1/15.
//  Copyright (c) 2015 Filly Wang. All rights reserved.
//

#import "FWSwipePlayerViewController.h"

@interface FWSwipePlayerViewController ()
{
    NSDictionary *infoDict;
    FWSwipePlayerConfig *config;
    NSArray *dataList;
    
    UIViewController *attachViewController;
}

@end

@implementation FWSwipePlayerViewController

-(id)init
{
    self = [super init];
    if(self)
    {
        [self.view setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

-(void)updateMoviePlayerWithInfo:(NSDictionary * )dict
{
    [self updateMoviePlayerWithInfo:dict Config:[[FWSwipePlayerConfig alloc]init]];
}

-(void)updateMoviePlayerWithInfo:(NSDictionary * )dict Config:(FWSwipePlayerConfig*)configuration
{
    infoDict = dict;
    config = configuration;
    
    [self configPlayer];
}

- (void)updateMoviePlayerWithVideoList:(NSArray * )list Config:(FWSwipePlayerConfig*)configuration
{
    dataList = list;
    infoDict = list[0];
    config = configuration;
    [self configPlayer];
}

-(void)configPlayer
{
    if(self.moviePlayer != nil)
        self.moviePlayer = nil;
    config.currentVideoTitle = [infoDict objectForKey:@"title"];
    if(dataList)
    {
            //[self playWithSubtitles:subtitles currentSubtitle:currentSubtitle channels:channels currentChannel:currentChannel startAt:time];
            
            self.moviePlayer = [[FWSwiperPlayerController alloc]initWithContentDataList:dataList andConfig:config];
        
    }
    else
        self.moviePlayer = [[FWSwiperPlayerController alloc]initWithContentURL:[NSURL URLWithString: [infoDict objectForKey:@"url"]] andConfig:config];
    [self.moviePlayer updatePlayerFrame:CGRectMake(0, 20, self.view.frame.size.width, config.topPlayerHeight)];
    [self.view addSubview: self.moviePlayer.view];
}

- (void)attachTo:(UIViewController*)viewController
{
    attachViewController = viewController;
    [attachViewController.view addSubview:self.moviePlayer.view];
    [self.moviePlayer attachTo:attachViewController];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIDeviceOrientationLandscapeLeft;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (void)playStartAt:(NSTimeInterval)time
{
    [self.moviePlayer playStartAt:time];
}

-(void)stopAndRemove
{
    [self.moviePlayer stopAndRemove];
}


#pragma mark - status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
