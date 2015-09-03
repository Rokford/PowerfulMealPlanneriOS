//
//  CalendarViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 31.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "CalendarViewController.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "RecipesToCheckViewController.h"

@interface CalendarViewController ()

@property(weak, nonatomic) IBOutlet FSCalendar *calendar;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic) NSMutableDictionary *thisMonthDaysWithRecipes;
@property(assign, nonatomic) BOOL inDaysSelectionMode;
@property(strong, nonatomic) NSDate *dateTapped;
@property(weak, nonatomic) IBOutlet UITableView *recipesTableView;
@property(strong, nonatomic)
    NSFetchedResultsController *fetchedResultsController;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *mealsAssignedLabel;

@end

@implementation CalendarViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.thisMonthDaysWithRecipes = [[NSMutableDictionary alloc] init];

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.managedObjectContext = appDelegate.managedObjectContext;

  [self fetchAndSetRecipesForMonth:self.calendar.currentMonth];

  [self.calendar setSelectedDate:[NSDate date]];

  NSCalendar *calendar = [NSCalendar currentCalendar];

  // components of current month
  NSDateComponents *dateComponents = [calendar
      components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
        fromDate:self.calendar.selectedDate];

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

- (void)viewWillAppear:(BOOL)animated
{
  NSDate *currentMonth = self.calendar.currentMonth;

  [self fetchAndSetRecipesForMonth:currentMonth];

  [self.calendar reloadData];
}

- (IBAction)addRecipe:(id)sender
{
}

- (void)fetchAndSetRecipesForMonth:(NSDate *)currentMonth
{
  NSCalendar *calendar = [NSCalendar currentCalendar];

  NSRange currentRange = [calendar rangeOfUnit:NSCalendarUnitDay
                                        inUnit:NSCalendarUnitMonth
                                       forDate:currentMonth];

  // days in current month
  NSInteger numberOfDays = currentRange.length;

  // components of current month
  NSDateComponents *dateComponents = [calendar
      components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
        fromDate:currentMonth];

  NSDateComponents *comps = [[NSDateComponents alloc] init];
  comps.year = dateComponents.year;
  comps.month = dateComponents.month;
  comps.day = 1;

  NSDate *firstDate = [calendar dateFromComponents:comps];

  comps.day = numberOfDays;

  NSDate *lastDate = [calendar dateFromComponents:comps];

  NSError *error = nil;

  NSPredicate *predicate = [NSPredicate
      predicateWithFormat:@"(%@ <= date && date <= %@)", firstDate, lastDate];

  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"Day"];

  [fetchRequest setPredicate:predicate];

  NSArray *resultsArray =
      [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

  if (error) return;

  for (NSManagedObject *object in resultsArray) {
    NSDate *date = [object valueForKey:@"date"];
    NSMutableSet *recipesForDay = [object mutableSetValueForKey:@"recipes"];

    [self.thisMonthDaysWithRecipes setObject:recipesForDay forKey:date];
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
  [self.recipesTableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  [self.recipesTableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
  switch (type) {
  case NSFetchedResultsChangeInsert: {
    [self.recipesTableView
        insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  case NSFetchedResultsChangeDelete: {
    [self.recipesTableView
        deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  case NSFetchedResultsChangeUpdate: {
    [self configureCell:[self.recipesTableView cellForRowAtIndexPath:indexPath]
            atIndexPath:indexPath];
    break;
  }
  case NSFetchedResultsChangeMove: {
    [self.recipesTableView
        deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    [self.recipesTableView
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
      [self.recipesTableView dequeueReusableCellWithIdentifier:@"RecipeRow"
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
    NSManagedObject *record =
        [self.fetchedResultsController objectAtIndexPath:indexPath];

    NSMutableSet *days = [record mutableSetValueForKey:@"days"];

    NSManagedObject *dayToRemove;

    for (NSManagedObject *day in days) {
      NSDate *date = [day valueForKey:@"date"];

      if ([date compare:self.calendar.selectedDate] == NSOrderedSame) {
        dayToRemove = day;
        break;
      }
    }

    [days removeObject:dayToRemove];
    [self.calendar reloadData];

    //    if (record) {
    //      [self.fetchedResultsController.managedObjectContext
    //      deleteObject:record];
    //    }
  }
}

#pragma mark - FSCalendar

- (void)calendar:(FSCalendar *)calendara didSelectDate:(NSDate *)date
{
  NSCalendar *calendar = [NSCalendar currentCalendar];

  // components of current month
  NSDateComponents *dateComponents = [calendar
      components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
        fromDate:self.calendar.selectedDate];

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

  self.fetchedResultsController = [[NSFetchedResultsController alloc]
      initWithFetchRequest:fetchRequest
      managedObjectContext:self.managedObjectContext
        sectionNameKeyPath:nil
                 cacheName:nil];

  [self.fetchedResultsController setDelegate:self];

  NSError *error = nil;
  [self.fetchedResultsController performFetch:&error];

  if (error) {
    NSLog(@"Unable to perform fetch.");
    NSLog(@"%@, %@", error, error.localizedDescription);
  }

  [self.recipesTableView reloadData];
}

- (BOOL)calendar:(FSCalendar *)calendar shouldSelectDate:(NSDate *)date
{
  return true;
}

- (NSString *)calendar:(FSCalendar *)calendar subtitleForDate:(NSDate *)date
{
  NSCalendar *calendarHelper = [NSCalendar currentCalendar];

  for (NSDate *dateKey in self.thisMonthDaysWithRecipes) {
    if ([calendarHelper isDate:dateKey inSameDayAsDate:date]) {
      NSMutableSet *recipes =
          [self.thisMonthDaysWithRecipes objectForKey:dateKey];

      if (!recipes.count)
        return nil;
      else
        return [NSString
            stringWithFormat:@"M: %@", [@(recipes.count) stringValue]];
    }
  }

  return nil;
}

- (void)calendarCurrentMonthDidChange:(FSCalendar *)calendar
{
  [self fetchAndSetRecipesForMonth:calendar.currentMonth];
}

- (BOOL)calendar:(FSCalendar *)calendar hasEventForDate:(NSDate *)date
{
  return false;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  RecipesToCheckViewController *controller = [segue destinationViewController];
  controller.date = self.calendar.selectedDate;
}

@end
