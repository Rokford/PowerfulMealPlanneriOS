//
//  PMPTableViewCell.h
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 13.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMPTableViewCell : UITableViewCell

@property(weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property(weak, nonatomic) IBOutlet UILabel *itemUnitLabel;
@property(weak, nonatomic) IBOutlet UILabel *itemQuantityLabel;

@end
