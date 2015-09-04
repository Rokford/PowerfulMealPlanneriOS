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
#import "UIAlertView+Blocks/UIAlertView+Blocks.h"

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
@property(weak, nonatomic) IBOutlet UIBarButtonItem *createListBarItem;
@property(assign, nonatomic) BOOL selectingDays;
@property(strong, nonatomic) NSDate *firstDay;
@property(strong, nonatomic) NSDate *lastDay;

@end

@implementation CalendarViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  _calendar.appearance.todayColor = [UIColor clearColor];
  _calendar.appearance.titleTodayColor = _calendar.appearance.titleDefaultColor;
  _calendar.appearance.subtitleTodayColor =
      _calendar.appearance.subtitleDefaultColor;

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

- (void)cancelSelectingDays
{
  self.selectingDays = NO;
  self.firstDay = nil;
  self.lastDay = nil;
  self.createListBarItem.title = @"Create list";

  [self.navigationItem setLeftBarButtonItem:nil animated:YES];

  [self.calendar reloadData];
}

- (IBAction)createList:(id)sender
{
  if (!self.selectingDays) {

    UIBarButtonItem *item =
        [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(cancelSelectingDays)];

    [self.navigationItem setLeftBarButtonItem:item animated:YES];

    [[[UIAlertView alloc]
            initWithTitle:@"Create Shopping List"
                  message:@"Tap the first day your shopping list should be "
                  @"generated for, then tap 'Select last day' in "
                  @"upper right corner and choose the last "
                  @"day.\n\nFinally, tap 'Finish the "
                  @"list' to complete your shopping list"
                 delegate:self
        cancelButtonTitle:@"Dismiss"
        otherButtonTitles:nil, nil] show];

    self.createListBarItem.title = @"Select last day";
    self.selectingDays = YES;
  } else {
    if (!self.firstDay) {
      NSDate *firstDay = self.calendar.selectedDate;
      self.firstDay = firstDay;

      NSDate *tomorrow = [firstDay dateByAddingTimeInterval:60 * 60 * 24 * 1];

      [self.calendar setSelectedDate:tomorrow];

      // do this after delay to avoid FSCalendar glitch
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC),
                     dispatch_get_main_queue(),
                     ^{ [self.calendar reloadData]; });

      self.createListBarItem.title = @"Finish the list";
    } else {

      if ([self.lastDay compare:self.firstDay] == NSOrderedAscending) {

        [[[UIAlertView alloc]
                initWithTitle:@"Wrong dates selected"
                      message:@"Last day should be after first one"
                     delegate:self
            cancelButtonTitle:@"Dismiss"
            otherButtonTitles:nil, nil] show];

      } else {

        [UIAlertView
                showWithTitle:@"Shopping list"
                      message:@"Would you like to add ingredients to already "
                      @"existing shopping list or create a new one?"
            cancelButtonTitle:@"Add"
            otherButtonTitles:@[ @"Create new" ]
                     tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                       if (buttonIndex == [alertView cancelButtonIndex]) {
                         [self createShoppingList:NO];
                       } else {
                         [self createShoppingList:YES];
                       }
                     }];
      }
    }
  }
}

- (void)createShoppingList:(BOOL)deleteOld
{
  NSMutableArray *shoppingItems = [[NSMutableArray alloc] init];

  if (deleteOld) {
    [self deleteAllEntities:@"ShoppingItem"];
  } else {
    NSFetchRequest *shoppingItemsFetchRequest =
        [[NSFetchRequest alloc] initWithEntityName:@"ShoppingItem"];

    NSError *error = nil;

    NSArray *shoppingItemsArray =
        [self.managedObjectContext executeFetchRequest:shoppingItemsFetchRequest
                                                 error:&error];

    [shoppingItems addObjectsFromArray:shoppingItemsArray];
  }

  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];

  NSPredicate *predicate = [NSPredicate
      predicateWithFormat:
          @"SUBQUERY(days, $day, $day.date >= %@ && $day.date <= %@).@count >0",
          self.firstDay, self.lastDay];

  [fetchRequest setPredicate:predicate];

  NSError *error = nil;

  NSMutableArray *newIngredients = [[NSMutableArray alloc] init];

  NSArray *recipesArray =
      [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

  for (NSManagedObject *recipe in recipesArray) {
    NSMutableSet *recipesDays = [recipe mutableSetValueForKey:@"days"];

    int ingredientsMultiplier = 0;

    for (NSManagedObject *day in recipesDays) {
      NSDate *recipeDate = [day valueForKey:@"date"];

      if ([self date:recipeDate
              isBetweenDate:self.firstDay
                    andDate:self.lastDay])
        ingredientsMultiplier++;
    }

    NSMutableSet *recipesIngredients =
        [recipe mutableSetValueForKey:@"ingredients"];

    for (NSManagedObject *ingredient in recipesIngredients) {

      NSEntityDescription *entityDescription =
          [NSEntityDescription entityForName:@"ShoppingItem"
                      inManagedObjectContext:self.managedObjectContext];

      NSManagedObject *item =
          [[NSManagedObject alloc] initWithEntity:entityDescription
                   insertIntoManagedObjectContext:self.managedObjectContext];

      [item setValue:[ingredient valueForKey:@"itemName"] forKey:@"itemName"];
      [item setValue:[ingredient valueForKey:@"unit"] forKey:@"unit"];
      [item setValue:[ingredient valueForKey:@"category"] forKey:@"category"];

      CGFloat quantity = [[ingredient valueForKey:@"quantity"] floatValue];
      quantity *= ingredientsMultiplier;

      [item setValue:@(quantity) forKey:@"quantity"];

      [newIngredients addObject:item];
    }
  }

  // check against duplicates in shopping list array
  for (NSManagedObject *item in newIngredients) {
    BOOL newShoppingItem = YES;
    for (NSManagedObject *ingr2 in shoppingItems) {
      if ([[item valueForKey:@"itemName"]
              isEqualToString:[ingr2 valueForKey:@"itemName"]] &&
          [[item valueForKey:@"unit"]
              isEqualToString:[ingr2 valueForKey:@"unit"]]) {
        newShoppingItem = NO;
        CGFloat quantity = [[ingr2 valueForKey:@"quantity"] floatValue];
        quantity += [[item valueForKey:@"quantity"] floatValue];

        [ingr2 setValue:@(quantity) forKey:@"quantity"];

        [self.managedObjectContext deleteObject:item];
      }
    }
  }

  if (![self.managedObjectContext save:&error]) {
    NSLog(@"Unable to save managed object context.");
    NSLog(@"%@, %@", error, error.localizedDescription);
  }

  self.selectingDays = NO;
  self.firstDay = nil;
  self.lastDay = nil;
  self.createListBarItem.title = @"Create list";

  [self.calendar reloadData];
}

- (void)deleteAllEntities:(NSString *)nameEntity
{
  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:nameEntity];
  [fetchRequest setIncludesPropertyValues:NO]; // only fetch the managedObjectID

  NSError *error;
  NSArray *fetchedObjects =
      [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
  for (NSManagedObject *object in fetchedObjects) {
    [self.managedObjectContext deleteObject:object];
  }

  error = nil;
  [self.managedObjectContext save:&error];
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

  if (self.selectingDays && self.firstDay) {
    self.lastDay = date;

    if (self.lastDay) {

      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC),
                     dispatch_get_main_queue(),
                     ^{ [self.calendar reloadData]; });
    }
  }
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
  if (self.selectingDays && self.firstDay) {
    if ([date compare:self.firstDay] == NSOrderedAscending) return NO;

    if ([date compare:self.lastDay] == NSOrderedDescending) return NO;

    return YES;
  } else
    return NO;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  RecipesToCheckViewController *controller = [segue destinationViewController];
  controller.date = self.calendar.selectedDate;
}

#pragma mark - utilities

- (BOOL)date:(NSDate *)date
    isBetweenDate:(NSDate *)beginDate
          andDate:(NSDate *)endDate
{
  if ([date compare:beginDate] == NSOrderedAscending) return NO;

  if ([date compare:endDate] == NSOrderedDescending) return NO;

  return YES;
}

@end
