//
//  RecipesForCalendarTableViewController.h
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 01.09.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface RecipesForCalendarTableViewController
    : UITableViewController <NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) NSDate *date;

@end
