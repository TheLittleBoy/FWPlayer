//
//  FWSwipePlayerMenuLayer.m
//  FWDraggableSwipePlayer
//
//  Created by  MAC on 15/10/20.
//  Copyright © 2015年 Filly Wang. All rights reserved.
//

#import "FWSwipePlayerMenuLayer.h"
#import "FWPlayerColorUtil.h"

@interface FWSwipePlayerMenuLayer()
{
    FWPlayerColorUtil *colorUtil;
    
    UIImageView *menuView;
    
    NSString *sectionTitle;
}

@end


@implementation FWSwipePlayerMenuLayer

- (id)initLayerAttachTo:(UIView *)view
{
    self = [super initLayerAttachTo:view];
    if(self)
    {
        colorUtil = [[FWPlayerColorUtil alloc]init];
        [self configSettingView];
    }
    return self;
}

-(void)configSettingView
{
    menuView = [[UIImageView alloc] init];
    menuView.userInteractionEnabled = YES;
    menuView.backgroundColor = [colorUtil colorWithHex:@"#000000" alpha:0.5];
    
    
    self.listView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
    self.listView.dataSource = self;
    self.listView.delegate = self;
    [self.listView setBackgroundColor:[colorUtil colorWithHex:@"#000000" alpha:0.2]];
    [self.listView setSeparatorColor:[colorUtil colorWithHex:@"#F0F0F0" alpha:0.3]];
    [menuView addSubview:self.listView];
    self.datalist = nil;
    
    [self.layerView addSubview:menuView];
}

- (void)updateFrame:(CGRect)frame
{
    [super updateFrame:frame];
    menuView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.listView.frame = menuView.bounds;
}

-(void)disappear
{
    CGFloat x = self.rootView.frame.size.width;
    CGFloat y = self.layerView.frame.origin.y;
    CGFloat w = self.layerView.frame.size.width;
    CGFloat h = self.layerView.frame.size.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        //
        self.layerView.frame = CGRectMake(x, y, w, h);
        
    } completion:^(BOOL finished) {
        //
        [menuView setHidden:YES];
        [super disappear];
        [super remove];
    }];
}

- (void)show
{
    [super show];
    [super attach];
    [menuView setHidden:NO];
    
    CGFloat x = self.rootView.frame.size.width - self.layerView.frame.size.width;
    CGFloat y = self.layerView.frame.origin.y;
    CGFloat w = self.layerView.frame.size.width;
    CGFloat h = self.layerView.frame.size.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        //
        self.layerView.frame = CGRectMake(x, y, w, h);
        
    } completion:^(BOOL finished) {
        //
    }];
}


-(void)reloadSelectViewWithArray:(NSArray*)list withSectionTitle:(NSString*)title
{
    self.datalist = list;
    sectionTitle = title;
    [self.listView reloadData];
}

#pragma mark tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.datalist)
        return [self.datalist count];
    else
        return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if([sectionTitle isEqualToString: @""])
        return 0;
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 30)];
    view.backgroundColor = menuView.backgroundColor;
    UILabel *label = [[UILabel alloc]initWithFrame:view.frame];
    label.text = sectionTitle;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:12];
    [view addSubview:label];
    return view;
}

- (UITableViewHeaderFooterView *)headerViewForSection:(NSInteger)section
{
    if([sectionTitle isEqualToString:@""])
        return nil;
    
    UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc]init];
    view.textLabel.text = sectionTitle;
    return view;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tablecell"];
    
    if(cell==nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tablecell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.backgroundColor = self.listView.backgroundColor;
    if(self.datalist[[indexPath row]][@"title"])
        cell.textLabel.text = self.datalist[[indexPath row]][@"title"];
    else if(self.datalist[[indexPath row]][@"lang"])
        cell.textLabel.text = self.datalist[[indexPath row]][@"lang"];
    else
        cell.textLabel.text = @"test -- test";
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.textColor = [UIColor whiteColor];
    if([indexPath row] == 0)
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    else
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    if(self.delegate)
    {
        if([self.delegate respondsToSelector:@selector(didSelectRowAtIndexPath:)]){
            //[self.delegate didSelectRowAtIndexPath:sender];
        }
    }
}

@end
