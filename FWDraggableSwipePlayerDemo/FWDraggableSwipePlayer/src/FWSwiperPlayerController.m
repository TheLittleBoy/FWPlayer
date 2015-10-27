//
//  FWSwiperPlayerController.m
//  FWDraggableSwipePlayer
//
//  Created by Filly Wang on 20/1/15.
//  Copyright (c) 2015 Filly Wang. All rights reserved.
//  Edit by wangxuanao on 2015年10月

#import "FWSwiperPlayerController.h"
#import "FWSwipePlayerLoadingLayer.h"
#import "FWSwipePlayerBottomLayer.h"
#import "FWSwipePlayerMenuLayer.h"
#import "FWSwipePlayerNavLayer.h"


#define HiddenControlTime  5

NSString *FWSwipePlayerLockBtnOnclick = @"FWSwipePlayerLockBtnOnclick";
NSString *FWSwipePlayerMenuBtnOnclick = @"FWSwipePlayerMenuBtnOnclick";
NSString *FWSwipePlayerDoneBtnOnclick = @"FWSwipePlayerDoneBtnOnclick";
NSString *FWSwipePlayerPlayBtnOnclick = @"FWSwipePlayerPlayBtnOnclick";
NSString *FWSwipePlayerFullScreenBtnOnclick = @"FWSwipePlayerFullScreenBtnOnclick";
NSString *FWSwipePlayerNextEpisodeBtnOnclick = @"FWSwipePlayerNextEpisodeBtnOnclick";
NSString *FWSwipePlayerOnTap = @"FWSwipePlayerOnTap";


@interface FWSwiperPlayerController()<FWSwipePlayerBottomLayerDelegate, FWSwipePlayerMenuLayerDelegate, FWSwipePlayerNavLayerDelegate>
{
    FWSwipePlayerLoadingLayer *loadingLayer;
    FWSwipePlayerNavLayer *navLayer;

    FWSwipePlayerBottomLayer *bottomLayer;
    FWSwipePlayerMenuLayer *menuLayer;
    
    UIImageView *centerView;
    UIButton *playBtn;
    UIImageView *swipeView;
    UILabel *progressLabel;
    
    BOOL isPlaying;
    BOOL isFullScreen;
    BOOL isAnimationing;
    BOOL isShowingCtrls;
    BOOL needToHideController;
    BOOL isLock;
    BOOL isSmall;
    BOOL isMenuViewShow;
    BOOL isLoading;
    BOOL isSeeking;
    BOOL isShowingStatusBar;
    
    float curVolume;
    float curPlaytime;
    
    FWSwipePlayerConfig * config;
    FWPlayerColorUtil *colorUtil;
    
    CGFloat screenHeight;
    CGFloat screenWidth;
    
    NSURL *currentVideoUrl;
    NSArray *videoList;
    
    UIPanGestureRecognizer *swipeRecognizer;
    UIViewController * attachViewController;
    
    NSTimer *bandwidthTimer;
    
    CGPoint swipePoint;
}
@end

@implementation FWSwiperPlayerController

-(id)initWithContentURL:(NSURL *)url
{
    return [self initWithContentURL:url andConfig:[[FWSwipePlayerConfig alloc]init]];
}

- (id)initWithContentURL:(NSURL *)url andConfig:(FWSwipePlayerConfig*)configuration
{
    self = [super initWithContentURL:url];
    if(self)
    {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        screenWidth = screenRect.size.width;
        screenHeight = screenRect.size.height;
        
        self.view.frame = CGRectMake(0, 0, screenHeight, screenHeight);
        swipePoint = CGPointZero;
        currentVideoUrl = url;
        needToHideController = NO;
        isLock = NO;
        isSmall = NO;
        isLoading = YES;
        isMenuViewShow = NO;
        isSeeking = NO;
        config = configuration;
        colorUtil = [[FWPlayerColorUtil alloc]init];
        self.moveState = FWPlayerMoveNone;
        [self configControls];
        [self showControls];
    }
    return self;
}

- (id)initWithContentDataList:(NSArray *)list
{
    return [self initWithContentDataList:list andConfig:[[FWSwipePlayerConfig alloc]init]];
}

- (id)initWithContentDataList:(NSArray *)list andConfig:(FWSwipePlayerConfig*)configuration
{
    if([list count] > 0)
    {
        self = [super initWithContentURL:[NSURL URLWithString: [list[0] objectForKey:@"url"]]];
        if(self)
        {
            videoList = list;
            
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            screenWidth = screenRect.size.width;
            screenHeight = screenRect.size.height;
            
            self.view.frame = CGRectMake(0, 0, screenHeight, screenHeight);
            currentVideoUrl = [NSURL URLWithString: [list[0] objectForKey:@"url"]];
            needToHideController = NO;
            isLock = NO;
            isSmall = NO;
            isLoading = YES;
            isMenuViewShow = NO;
            config = configuration;
            colorUtil = [[FWPlayerColorUtil alloc]init];
            self.moveState = FWPlayerMoveNone;
            [self configControls];
            [self showControlsAndHiddenControlsAfter:HiddenControlTime];
        }
        return self;
    }
    else
        return [self initWithContentURL:[NSURL URLWithString:@""] andConfig:[[FWSwipePlayerConfig alloc]init]];
}



- (void)configControls {
    [self initMoviePlayer];
    [self configNavControls];
    [self configCenterControls];
    [self configPreloadPage];
    [self configBottomControls];
    [self configMenuView];
}

-(void)initMoviePlayer
{
    [self setControlStyle:MPMovieControlStyleNone];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateChanged:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDurationAvailableNotification:)
                                                 name:MPMovieDurationAvailableNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActiviy:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(UIDeviceOrientationDidChangeNotification:)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSwipePlayerViewStateChange:)
                                                 name:FWSwipePlayerViewStateChange object:nil];
    
    UIControl *control = [[UIControl alloc] initWithFrame:self.view.frame];
    control.backgroundColor = [UIColor clearColor];
    [control addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:control];
    
    if(!config.draggable)
    {
        swipeRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)] ;
        [swipeRecognizer setMinimumNumberOfTouches:1];
        [swipeRecognizer setMaximumNumberOfTouches:1];
        [swipeRecognizer setDelegate:self];
        [self.view addGestureRecognizer:swipeRecognizer];
    }
    
}

-(void)configCenterControls
{
    centerView = [[UIImageView alloc] initWithFrame:CGRectMake(screenWidth/2 - 100, config.topPlayerHeight/2 - 100, 200, 200)];
    centerView.userInteractionEnabled = NO;
    centerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:centerView];
    
    swipeView = [[UIImageView alloc] initWithFrame:CGRectMake((centerView.frame.size.width - 100) / 2, (centerView.frame.size.height - 70) / 2, 100, 70)];
    [swipeView setImage:[UIImage imageNamed:@"movie_play_gesture_forward"]];
    [swipeView setHidden:YES];
    [centerView addSubview:swipeView];
    
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom] ;
    playBtn.frame = CGRectMake((screenWidth - 35) / 2, (screenHeight - 35) / 2, 35, 35);
    playBtn.showsTouchWhenHighlighted = YES;
    [playBtn setBackgroundImage:[UIImage imageNamed:@"moviePlay"] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    [playBtn setAlpha:1];
    
    progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, swipeView.frame.origin.y + swipeView.frame.size.height, centerView.frame.size.width, 30)];
    progressLabel.text = @"--:--:-- / --:--:--";
    progressLabel.font = [UIFont systemFontOfSize:18];
    progressLabel.textAlignment = NSTextAlignmentCenter;
    progressLabel.textColor = [UIColor whiteColor];
    progressLabel.backgroundColor = [UIColor clearColor];
    [progressLabel setHidden:YES];
    [centerView addSubview:progressLabel];
}

-(void)configPreloadPage
{
    loadingLayer = [[FWSwipePlayerLoadingLayer alloc]initLayerAttachTo:self.view ];
    [loadingLayer attach];
    [self startBandwidthTimer];
}

-(void)configNavControls
{
    navLayer = [[FWSwipePlayerNavLayer alloc]initLayerAttachTo:self.view config:config];
    navLayer.delegate = self;
    [navLayer attach];
}

-(void)configBottomControls
{
    bottomLayer = [[FWSwipePlayerBottomLayer alloc]initLayerAttachTo:self.view];
    bottomLayer.delegate = self;
    [bottomLayer attach];
}

-(void)configMenuView
{
    menuLayer = [[FWSwipePlayerMenuLayer alloc]initLayerAttachTo:self.view];
    menuLayer.delegate = self;
    [menuLayer attach];
}

-(void)showControls
{
    if (isAnimationing) {
        return;
    }
    isAnimationing = YES;
    isShowingStatusBar = YES;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(setStatusBarHidden:)])
            [self.delegate setStatusBarHidden:NO];
    
    [UIView animateWithDuration:0.2 animations:^{
        [navLayer show];
        [bottomLayer show];
        playBtn.alpha = 1;
    } completion:^(BOOL finished) {
        isAnimationing = NO;
        isShowingCtrls = YES;
    }];
}

-(void)showControlsAndHiddenControlsAfter:(NSTimeInterval)time
{
    [self showControls];
    if(time != 0)
        [self performSelector:@selector(hiddenControls) withObject:nil afterDelay:time];
}

-(void)hiddenControls
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControls) object:nil];
    
    if (isAnimationing) {
        return;
    }
    isAnimationing = YES;
    isShowingStatusBar = YES;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(setStatusBarHidden:)])
            [self.delegate setStatusBarHidden:YES];
    
    [UIView animateWithDuration:0.2 animations:^{
        [navLayer disappear];
        [bottomLayer disappear];
        playBtn.alpha = 0;
    } completion:^(BOOL finished) {
        isAnimationing = NO;
        isShowingCtrls = NO;
    }];
}

-(void)startBandwidthTimer
{
    [self stopBandwidthTimer];
    bandwidthTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
                                                    selector:@selector(retrieveTraffic:) userInfo:nil repeats:YES];
}

-(void)hiddenMenuView
{
    [menuLayer disappear];
    
    isMenuViewShow = NO;
}

#pragma mark slider
- (void)changePlayerProgress:(id)sender {
    isSeeking = YES;
    [self updatePlayBackTime:(bottomLayer.sliderProgress.value * self.duration)];
}
-(void)progressTouchUp:(id)sender
{
    isSeeking = NO;
    self.currentPlaybackTime = bottomLayer.sliderProgress.value * self.duration;

}

-(void)progressTouchDown:(id)sender
{
    
}

#pragma mark delegate
-(void)handleTap:(id)sender
{
    if (isShowingCtrls) {
        [self hiddenControls];
    } else {
        if(needToHideController)
        {
            
        }
        else if(!isMenuViewShow)
            [self showControlsAndHiddenControlsAfter:HiddenControlTime];
        else
        {
            [self hiddenMenuView];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerOnTap object:self userInfo:nil] ;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(tapInside:)])
            [self.delegate tapInside:sender];
}



-(void)fullScreenOnClick:(id)sender
{
    if (isFullScreen) {
        [bottomLayer.fullScreenBtn setBackgroundImage:[UIImage imageNamed:@"movieFullscreen"] forState:UIControlStateNormal];
        //[self setOrientation:UIDeviceOrientationPortrait];
        isFullScreen = NO;
        self.scalingMode = MPMovieScalingModeAspectFit;
    } else {
        [bottomLayer.fullScreenBtn setBackgroundImage:[UIImage imageNamed:@"movieEndFullscreen"] forState:UIControlStateNormal];
        //[self setOrientation:UIDeviceOrientationLandscapeLeft];
        isFullScreen = YES;
        self.scalingMode = MPMovieScalingModeFill;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerFullScreenBtnOnclick object:self userInfo:nil] ;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(fullScreenBtnOnClick:)])
            [self.delegate fullScreenBtnOnClick:sender];
}

-(void)playBtnOnClick:(id)sender
{
    if (isPlaying) {
        [self pause];
    } else {
        [self play];
        [self showControlsAndHiddenControlsAfter:HiddenControlTime];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerPlayBtnOnclick object:self userInfo:nil] ;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(playBtnOnClick:)])
            [self.delegate playBtnOnClick:sender];
}

-(void)settingViewCloseBtnOnClick:(id)sender
{
    [menuLayer disappear];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerSettingViewCloseBtnOnclick object:self userInfo:nil] ;
//    
//    if(self.delegate)
//        if([self.delegate respondsToSelector:@selector(settingViewCloseBtnOnClick:)])
//            [self.delegate settingViewCloseBtnOnClick:sender];
}

-(void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //menu
    [menuLayer disappear];
}

-(void)downloadBtnOnClick:(id)sender
{
    isLock = !isLock;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerLockBtnOnclick object:self userInfo:nil] ;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(lockScreenBtnOnClick:)])
            [self.delegate lockScreenBtnOnClick:sender];
}

-(void)doneBtnOnClick:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerDoneBtnOnclick object:self userInfo:nil] ;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(doneBtnOnClick:)])
            [self.delegate doneBtnOnClick:sender];
}

-(void)menuBtnOnClick:(id)sender
{
    [self hiddenControls];
    [menuLayer show];
    
    isMenuViewShow = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerMenuBtnOnclick object:self userInfo:nil] ;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(menuBtnOnClick:)])
            [self.delegate menuBtnOnClick:sender];
}

-(void)nextEpisodeBtnOnClick:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerNextEpisodeBtnOnclick object:self userInfo:nil] ;
    
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(nextEpisodeBtnOnClick:)])
            [self.delegate nextEpisodeBtnOnClick:sender];
}

#pragma swipePlayerGesture

- (void)swipe:(id)sender
{
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded)
    {
        [self moveStateEnd:translatedPoint];
    }
    else
    {
        if(self.moveState == FWPlayerMoveNone)
        {
            if( fabs(swipePoint.y - translatedPoint.y) > 3)
            {
                self.moveState = FWPlayerMoveVolume;
            }
            else if( fabs(translatedPoint.y) < 4 && fabs(translatedPoint.x) > 5)
            {
                self.moveState = FWPlayerMoveProgress;
            }
        }
        
        if (self.moveState == FWPlayerMoveVolume) {
            
            if (fabs(swipePoint.y - translatedPoint.y)>20) {
                [self movingStateChange:CGPointMake(translatedPoint.x, swipePoint.y - translatedPoint.y)];
                swipePoint = translatedPoint;
            }
            
        }else if (self.moveState == FWPlayerMoveProgress)
        {
            [self movingStateChange:translatedPoint];
        }
        
    }
}

-(void)moveStateEnd :(CGPoint)point
{
    switch (self.moveState) {
        case FWPlayerMoveProgress:
            [self progressHide:point];
            break;
        case FWPlayerMoveVolume:
            [self volumeHide:point];
            break;
        default:
            break;
    }
    self.moveState = FWPlayerMoveNone;
}

-(void)volumeHide:(CGPoint)point
{
    swipePoint = CGPointZero;
    [swipeView setHidden:YES];
}

-(void)brightHide:(CGPoint)point
{
    [swipeView setHidden:YES];
}

-(void)progressHide:(CGPoint)point
{
    int progressNumber = point.x;
    NSTimeInterval time = self.currentPlaybackTime + (int)(progressNumber / 10);
    if(time < 0)
        time = 0;
    [self setCurrentPlaybackTime:time];
    if(isPlaying)
        [self play];
    [swipeView setHidden:YES];
    [progressLabel setHidden:YES];
}

-(void)movingStateChange:(CGPoint)point
{
    switch (self.moveState) {
        case FWPlayerMoveProgress:
            [self progressShow:point];
            break;
        case FWPlayerMoveVolume:
            [self volumeShow:point];
            break;
        default:
            break;
    }
}

-(void)progressShow:(CGPoint)point
{
    int number = point.x;
    [swipeView setImage:[UIImage imageNamed:number > 0 ? @"movie_play_gesture_forward" : @"movie_play_gesture_rewind" ]];
    
    [self showSwipeView];
    
    [progressLabel setHidden:NO];
    if((self.currentPlaybackTime + (int)(number / 10)) < 0 )
    {
        progressLabel.text = [NSString stringWithFormat:@"%@ / %@" ,[self convertStringFromInterval:0],[self convertStringFromInterval:self.duration]];
    }
    else
    {
        progressLabel.text = [NSString stringWithFormat:@"%@ / %@" ,[self convertStringFromInterval:self.currentPlaybackTime + (int)(number / 10)],[self convertStringFromInterval:self.duration]];
    }
    if(isPlaying)
        [self temporyaryPause];
    
}

-(void)volumeShow:(CGPoint)point
{
    if(!isMenuViewShow)
    {
        int number = point.y;
        
        float volume0 = [MPMusicPlayerController applicationMusicPlayer].volume;
        //MPVolumeView
        float add = number > 0 ? 0.0625:-0.0625;
        float volume = volume0 + add;
        volume = floorf(volume * 100) / 100;
        
        if(volume != volume0)
            [MPMusicPlayerController applicationMusicPlayer].volume = volume;
        
    }
}

-(void)showSwipeView
{
    [swipeView setHidden:NO];
    if(isShowingCtrls)
        [self hiddenControls];
}


- (void) monitorPlaybackTime {
    bottomLayer.cacheProgress.value = self.playableDuration;
    
    if(self.playbackState == MPMoviePlaybackStatePlaying)
    {
        if(!isSeeking)
        {
            bottomLayer.sliderProgress.value = self.currentPlaybackTime * 1.0 / self.duration;
            [self updatePlayBackTime:self.currentPlaybackTime];
        }
    }
    else if(self.playbackState == MPMoviePlaybackStateSeekingForward || self.playbackState == MPMoviePlaybackStateSeekingBackward || self.playbackState ==MPMoviePlaybackStateStopped || self.playbackState ==MPMoviePlaybackStatePaused)
    {
        [self updatePlayBackTime:(bottomLayer.sliderProgress.value * self.duration)];
    }
}

-(void)updatePlayBackTime:(float)seekTime
{
    bottomLayer.currentPlayTimeLabel.text =[self convertStringFromInterval:seekTime];
    int remainTime = self.duration - seekTime;
    if(remainTime < 0)
        remainTime = - remainTime;
    bottomLayer.remainPlayTimeLabel.text = [self convertStringFromInterval:remainTime];
    
    if (self.duration != 0 && self.currentPlaybackTime >= self.duration - 1)
    {
        self.currentPlaybackTime = 0;
        bottomLayer.sliderProgress.value = 0;
        bottomLayer.currentPlayTimeLabel.text =[self convertStringFromInterval:self.currentPlaybackTime];
        [self pause];
        [playBtn setBackgroundImage:[UIImage imageNamed:@"moviePlay"] forState:UIControlStateNormal];
        isPlaying = NO;
        
    } else {
        if (isPlaying) {
            [self performSelector:@selector(monitorPlaybackTime) withObject:nil afterDelay:1];
        }
    }

}

-(void)setOrientation:(int)orientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (NSString *)convertStringFromInterval:(NSTimeInterval)timeInterval {
    int hour = (int)timeInterval/3600;
    int min = (int)timeInterval%3600/60;
    int second = (int)timeInterval%3600%60;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hour,min, second];
}

-(void)updatePlayerFrame:(CGRect)rect
{
    CGFloat viewWidth = rect.size.width;
    CGFloat viewHeight = rect.size.height;
    
    self.view.frame = rect;
    
    centerView.frame = CGRectMake(viewWidth/2 - 100, viewHeight/2 - 100, 200, 200);
    
    [loadingLayer updateFrame:CGRectMake(viewWidth/2-50, viewHeight/2-50, 100, 100)];
    [navLayer updateFrame:CGRectMake(0, 0, viewWidth, 60)];
    [menuLayer updateFrame:CGRectMake(viewWidth, 0, 220, viewHeight)];
    
    [bottomLayer updateFrame:CGRectMake(0, viewHeight - 40, viewWidth, 40)];
    
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    [navLayer orientationChange:orientation];
    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
        playBtn.frame = CGRectMake(viewWidth/2 - 35, viewHeight/2 - 35, 75, 75);
        swipeView.frame = CGRectMake((centerView.frame.size.width - 100) / 2, (centerView.frame.size.height - 70) / 2, 100, 70);
    }
    else if(orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        playBtn.frame = CGRectMake(viewWidth/2 - 15, viewHeight/2 - 15, 35, 35);
        swipeView.frame = CGRectMake((centerView.frame.size.width - 35) / 2, (centerView.frame.size.height - 35) / 2, 35, 35);
    }
    else
    {
        playBtn.frame = CGRectMake(viewWidth/2 - 15, viewHeight/2 - 15, 35, 35);
    }
    
    progressLabel.frame = CGRectMake(0, swipeView.frame.origin.y + swipeView.frame.size.height, centerView.frame.size.width, 30);
    
}

- (void)stopLoading
{
    if(isLoading)
    {
        isLoading = NO;
        [loadingLayer remove];
        [self.view addSubview:playBtn];
    }
}

-(void)startLoading
{
    if(!isLoading)
    {
        [playBtn removeFromSuperview];
        isLoading = YES;
        [loadingLayer attach];
    }
}

#pragma mark playerDelagate
-(void)moviePlayerLoadStateChanged:(NSNotification*)notification
{
    if((self.loadState & MPMovieLoadStateStalled) == MPMovieLoadStateStalled)
    {
        [self startLoading];
    }
    else
    {
        if([self loadState] == MPMovieLoadStatePlayable  && curPlaytime != 0)
        {
            [self setInitialPlaybackTime:curPlaytime - 1];
            [self setCurrentPlaybackTime:curPlaytime];
            [self play];
            curPlaytime = 0;
        }
        else if ([self loadState] != MPMovieLoadStateUnknown)
        {
            [self stopLoading];
        }
        if(isPlaying)
            [self play];
    }
}

-(void)moviePlayBackDidFinish:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    if(self.delegate != nil)
        if ([self.delegate  respondsToSelector:@selector(didFinishPlay:)])
            [self.delegate didFinishPlay:currentVideoUrl];
}

-(void)handleDurationAvailableNotification:(NSNotification*)notification
{
    bottomLayer.cacheProgress.maximumValue = self.duration;
    bottomLayer.currentPlayTimeLabel.text = [self convertStringFromInterval:self.currentPlaybackTime];
    bottomLayer.remainPlayTimeLabel.text = [self convertStringFromInterval:self.duration - self.currentPlaybackTime];
}

- (void)becomeActiviy:(NSNotification *)notify {
    
}

- (void)enterBackground:(NSNotification *)notity {
    [super pause];
    [playBtn setBackgroundImage:[UIImage imageNamed:@"moviePlay"] forState:UIControlStateNormal];
    isPlaying = NO;
}

-(void)UIDeviceOrientationDidChangeNotification:(NSNotification *)notity
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight )
    {
        if(config.rotatable && !isSmall)
            [self updatePlayerFrame:CGRectMake(0, 0, screenHeight, screenWidth)];
    }
    else if(orientation == UIDeviceOrientationPortrait)
    {
        
        return;
        
        if(self.view.frame.size.height > config.topPlayerHeight && !isLock)
            [self updatePlayerFrame:CGRectMake(0, 20, screenWidth, config.topPlayerHeight)];
    }
}

-(void)handleSwipePlayerViewStateChange:(NSNotification *)notity
{
    isSmall = [[[notity userInfo] valueForKey:@"isSmall"] boolValue];
    if(isSmall)
        needToHideController = YES;
    else
        needToHideController = NO;
    
    [self hiddenControls];
}

#pragma mark timer

- (void)retrieveTraffic:(NSTimer*) timer {
    MPMovieAccessLog *log = self.accessLog;
    if(log != nil) {
        double bt = [[log.events objectAtIndex:log.events.count - 1] observedBitrate];
        
        if(loadingLayer)
        {
            [loadingLayer updateLoadingText:[NSLocalizedString(@"loading", @"loading..") stringByAppendingString : [NSString stringWithFormat: @"%.1f Kbps/s", bt / 1024]]];
            
        }
    }
}


#pragma mark player base control

-(void)play
{
    [super play];
    [playBtn setBackgroundImage:[UIImage imageNamed:@"moviePause"] forState:UIControlStateNormal];
    isPlaying = YES;
    [self monitorPlaybackTime];
}

-(void)temporyaryPause
{
    [self pause];
    isPlaying = YES;
}

-(void)pause
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(monitorPlaybackTime) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControls) object:nil];
    [playBtn setBackgroundImage:[UIImage imageNamed:@"moviePlay"] forState:UIControlStateNormal];
    [super pause];
    isPlaying = NO;
}

-(void)stop
{
    [super stop];
    isPlaying = NO;
}

-(void)stopBandwidthTimer
{
    if(bandwidthTimer)
    {
        [bandwidthTimer invalidate];
        bandwidthTimer = nil;
    }
}

-(void)stopAndRemove
{
    [self stop];
    [self endPlayer];
}

-(void)playStartAt:(NSTimeInterval)time
{
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self setInitialPlaybackTime:time];
        [self setCurrentPlaybackTime:time];
        [self play];
    });
}

- (void)endPlayer{
    [navLayer remove];
    [bottomLayer remove];
    [centerView removeFromSuperview];
    [self.view removeFromSuperview];
    
    [self stopBandwidthTimer];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(monitorPlaybackTime) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControls) object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerLoadStateDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMovieDurationAvailableNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:FWSwipePlayerViewStateChange
                                                  object:nil];
}

- (void)attachTo:(UIViewController*)controller
{
    attachViewController = controller;
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if([touch.view isKindOfClass:[UISlider class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
