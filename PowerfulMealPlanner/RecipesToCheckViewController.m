//
//  RecipesToCheckViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 01.09.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "RecipesToCheckViewController.h"
#import "AppDelegate.h"

@interface RecipesToCheckViewController ()

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic) NSArray *recipesArray;
@property(strong, nonatomic) NSMutableArray *checkedItems;

@end

@implementation RecipesToCheckViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  //  self.tableView.allowsMultipleSelection = TRUE;

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.managedObjectContext = appDelegate.managedObjectContext;

  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];

  NSError *error = nil;

  self.recipesArray =
      [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

  self.checkedItems =
      [[NSMutableArray alloc] initWithCapacity:self.recipesArray.count];

  for (int i = 0; i < self.recipesArray.count; i++) {
    [self.checkedItems insertObject:@(NO) atIndex:i];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)addChecked:(id)sender
{
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
      [[NSFetchRequest alloc] initWithEntityName:@"Day"];

  NSPredicate *predicate = [NSPredicate
      predicateWithFormat:@"(%@ <= date && date <= %@)", firstDate, lastDate];

  [fetchRequest setPredicate:predicate];

  NSError *error = nil;

  NSArray *resultsArray =
      [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

  if (error) return;

  if (resultsArray.count > 0) {
    // there already is this Day
    NSManagedObject *day = resultsArray[0];

    NSMutableSet *recipes = [day mutableSetValueForKey:@"recipes"];

    for (int i = 0; i < self.recipesArray.count; i++) {
      if ([self.checkedItems[i] boolValue])
        [recipes addObject:self.recipesArray[i]];
    }

    NSError *error = nil;
    if (![day.managedObjectContext save:&error]) {
      NSLog(@"Unable to save managed object context.");
      NSLog(@"%@, %@", error, error.localizedDescription);
    }

  } else {
    // create new Day object
    NSManagedObject *day = [[NSManagedObject
            alloc] initWithEntity:[NSEntityDescription entityForName:@"Day"
                                              inManagedObjectContext:
                                                  self.managedObjectContext]
        insertIntoManagedObjectContext:self.managedObjectContext];

    NSMutableSet *recipes = [[NSMutableSet alloc] init];

    for (int i = 0; i < self.recipesArray.count; i++) {
      if ([self.checkedItems[i] boolValue])
        [recipes addObject:self.recipesArray[i]];
    }

    [day setValue:self.date forKey:@"date"];
    [day setValue:recipes forKey:@"recipes"];

    NSError *error = nil;
    if (![day.managedObjectContext save:&error]) {
      NSLog(@"Unable to save managed object context.");
      NSLog(@"%@, %@", error, error.localizedDescription);
    }
  }

  [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.recipesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"RecipeRow"
                                      forIndexPath:indexPath];

  NSManagedObject *recipe = [self.recipesArray objectAtIndex:indexPath.row];

  NSString *name = [recipe valueForKey:@"recipeName"];

  cell.textLabel.text = name;
  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView cellForRowAtIndexPath:indexPath].accessoryType =
      UITableViewCellAccessoryCheckmark;

  self.checkedItems[indexPath.row] = @(YES);
}

- (void)tableView:(UITableView *)tableView
    didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView cellForRowAtIndexPath:indexPath].accessoryType =
      UITableViewCellAccessoryNone;

  self.checkedItems[indexPath.row] = @(NO);
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath
*)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath]
withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the
array, and add a new row to the table view
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath
*)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath
*)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
