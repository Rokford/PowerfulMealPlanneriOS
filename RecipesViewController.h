//
//  RecipesViewController.h
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 26.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface RecipesViewController
    : UITableViewController <NSFetchedResultsControllerDelegate>

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
