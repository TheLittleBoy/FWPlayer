//
//  FWSwipePlayerMenuLayer.h
//  FWDraggableSwipePlayer
//
//  Created by  MAC on 15/10/20.
//  Copyright © 2015年 Filly Wang. All rights reserved.
//

#import "FWSwipePlayerLayer.h"

@protocol FWSwipePlayerMenuLayerDelegate <NSObject>

-(void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface FWSwipePlayerMenuLayer : FWSwipePlayerLayer <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign)id<FWSwipePlayerMenuLayerDelegate> delegate;

@property (nonatomic, strong)UITableView *listView;
@property (nonatomic, strong)NSArray *datalist;

- (void)reloadSelectViewWithArray:(NSArray*)list withSectionTitle:(NSString*)title;

@end
