//
//  ViewController.h
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 10.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ShoppingListViewController
    : UITableViewController <UITableViewDelegate, UITableViewDataSource,
                             NSFetchedResultsControllerDelegate>

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(weak, nonatomic) IBOutlet UISwitch *listSwitch;

@end
