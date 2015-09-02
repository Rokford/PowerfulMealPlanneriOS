//
//  RecipesForCalendarTableViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 01.09.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "RecipesForCalendarTableViewController.h"
#import "AppDelegate.h"
#import "RecipesToCheckViewController.h"

@interface RecipesForCalendarTableViewController ()

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic)
    NSFetchedResultsController *fetchedResultsController;

@end

@implementation RecipesForCalendarTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.managedObjectContext = appDelegate.managedObjectContext;

  NSCalendar *calendar = [NSCalendar currentCalendar];

  // components of current month
  NSDateComponents *dateComponents = [calendar
      components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
        fromDate:self.date];

  NSDateComponents *comps = [[NSDateComponents alloc] init];
  comps.year = dateComponents.year;
  comps.month = dateComponents.month;
  comps.day = dateComponents.day;
  comps.hour = 0;
  comps.minute = 0;
  comps.second = 0;

  NSDate *firstDate = [calendar dateFromComponents:comps];

  comps.hour = 23;
  comps.minute = 59;
  comps.second = 59;

  NSDate *lastDate = [calendar dateFromComponents:comps];

  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];

  [fetchRequest setSortDescriptors:@[
    [NSSortDescriptor sortDescriptorWithKey:@"recipeName" ascending:YES]
  ]];

  NSPredicate *predicate = [NSPredicate
      predicateWithFormat:
          @"SUBQUERY(days, $day, $day.date >= %@ && $day.date <= %@).@count >0",
          firstDate, lastDate];

  [fetchRequest setPredicate:predicate];

  if (!self.fetchedResultsController) {
    self.fetchedResultsController = [[NSFetchedResultsController alloc]
        initWithFetchRequest:fetchRequest
        managedObjectContext:self.managedObjectContext
          sectionNameKeyPath:nil
                   cacheName:nil];

    [self.fetchedResultsController setDelegate:self];
  }

  NSError *error = nil;
  [self.fetchedResultsController performFetch:&error];

  if (error) {
    NSLog(@"Unable to perform fetch.");
    NSLog(@"%@, %@", error, error.localizedDescription);
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - fetched results controller

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
  switch (type) {
  case NSFetchedResultsChangeInsert: {
    [self.tableView
        insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  case NSFetchedResultsChangeDelete: {
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  case NSFetchedResultsChangeUpdate: {
    [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath]
            atIndexPath:indexPath];
    break;
  }
  case NSFetchedResultsChangeMove: {
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView
        insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  NSArray *sections = [self.fetchedResultsController sections];
  id<NSFetchedResultsSectionInfo> sectionInfo =
      [sections objectAtIndex:section];

  return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell =
      [self.tableView dequeueReusableCellWithIdentifier:@"RecipeRow"
                                           forIndexPath:indexPath];

  // Configure Table View Cell
  [self configureCell:cell atIndexPath:indexPath];

  return cell;
}

- (void)configureCell:(UITableViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath
{
  // Fetch Record
  NSManagedObject *item =
      [self.fetchedResultsController objectAtIndexPath:indexPath];

  // Update Cell
  [cell.textLabel setText:[item valueForKey:@"recipeName"]];
}

- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Return NO if you do not want the specified item to be editable.
  return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the row from the data source
    [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                     withRowAnimation:UITableViewRowAnimationFade];
  }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  RecipesToCheckViewController *controller = [segue destinationViewController];
  controller.date = self.date;
}

@end
