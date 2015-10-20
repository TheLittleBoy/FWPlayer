//
//  FWSwipePlayerNavLayer.h
//  FWDraggableSwipePlayer
//
//  Created by Filly Wang on 9/3/15.
//  Copyright (c) 2015 Filly Wang. All rights reserved.
//

#import "FWSwipePlayerLayer.h"
#import "FWSwipePlayerConfig.h"

@protocol FWSwipePlayerNavLayerDelegate <NSObject>

-(void)doneBtnOnClick:(id)sender;
-(void)menuBtnOnClick:(id)sender;
-(void)downloadBtnOnClick:(id)sender;

@end

@interface FWSwipePlayerNavLayer : FWSwipePlayerLayer
@property (nonatomic, assign)id<FWSwipePlayerNavLayerDelegate> delegate;
@property (nonatomic, strong) UIButton *downloadBtn;
- (id)initLayerAttachTo:(UIView *)view config:(FWSwipePlayerConfig*)configuration;
- (void)orientationChange:(UIDeviceOrientation)orientation;
@end
