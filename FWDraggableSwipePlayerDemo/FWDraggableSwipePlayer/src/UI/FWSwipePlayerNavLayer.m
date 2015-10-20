//
//  FWSwipePlayerNavLayer.m
//  FWDraggableSwipePlayer
//
//  Created by Filly Wang on 9/3/15.
//  Copyright (c) 2015 Filly Wang. All rights reserved.
//

#import "FWSwipePlayerNavLayer.h"
#import "FWPlayerColorUtil.h"
@interface FWSwipePlayerNavLayer()
{
    FWPlayerColorUtil *colorUtil;
    FWSwipePlayerConfig *config;
    UIImageView *navView;
    UIButton *doneBtn;
    UIButton *menuBtn;
    UILabel *titleLabel;
}

@end

@implementation FWSwipePlayerNavLayer

- (id)initLayerAttachTo:(UIView *)view config:(FWSwipePlayerConfig*)configuration
{
    self = [super initLayerAttachTo:view];
    if(self)
    {
        colorUtil = [[FWPlayerColorUtil alloc]init];
        config = configuration;
        [self configNavView];
    }
    
    return self;
}

-(void)configNavView
{
    navView = [[UIImageView alloc] init];
    navView.userInteractionEnabled = YES;
    [colorUtil setGradientBlackToWhiteColor:navView];
    
    doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.showsTouchWhenHighlighted = YES;
    doneBtn.frame = CGRectMake(8, 6, 28, 28);
    [doneBtn setImage:[UIImage imageNamed:@"movieBack.png"] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(doneBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    if(!config.draggable)
        [navView addSubview:doneBtn];
    
    menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    menuBtn.showsTouchWhenHighlighted = YES;
    [menuBtn addTarget:self action:@selector(menuBtnOnClick:)forControlEvents:UIControlEventTouchUpInside];
    [menuBtn setImage:[UIImage imageNamed: @"movieMenu"] forState:UIControlStateNormal];
    [navView addSubview:menuBtn];
    
    self.downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom] ;
    self.downloadBtn.showsTouchWhenHighlighted = YES;
    [self.downloadBtn addTarget:self action:@selector(downloadBtnOnClick:)forControlEvents:UIControlEventTouchUpInside];
    [self.downloadBtn setImage:[UIImage imageNamed: @"movieBuffer"] forState:UIControlStateNormal];
    [self.downloadBtn setHidden:YES];
    [navView addSubview:self.downloadBtn];
    
    titleLabel = [[UILabel alloc] init];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.text = config.currentVideoTitle;
    [titleLabel setHidden:YES];
    [navView addSubview:titleLabel];
    
    [self.layerView addSubview:navView];
}

-(void)updateFrame:(CGRect)frame
{
    [super updateFrame:frame];
    titleLabel.frame =  CGRectMake(40, 12, frame.size.width - 140, 16);
    navView.frame = CGRectMake(0, 20, frame.size.width, frame.size.height-20);
    menuBtn.frame = CGRectMake(frame.size.width - 28 - 12, 6, 28, 28);
    self.downloadBtn.frame = CGRectMake(menuBtn.frame.origin.x  - 28 - 12, 6, 28,28);
}

- (void)orientationChange:(UIDeviceOrientation)orientation
{
    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
        [titleLabel setHidden:NO];
        [self.downloadBtn setHidden:NO];
    }
    else if(orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        [self.downloadBtn setHidden:YES];
        [titleLabel setHidden:YES];
    }
}

-(void)doneBtnOnClick:(id)sender
{
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(doneBtnOnClick:)])
            [self.delegate doneBtnOnClick:sender];
}

-(void)menuBtnOnClick:(id)sender
{
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(menuBtnOnClick:)])
            [self.delegate menuBtnOnClick:sender];
}

-(void)downloadBtnOnClick:(id)sender
{
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(downloadBtnOnClick:)])
            [self.delegate downloadBtnOnClick:sender];
}

@end
