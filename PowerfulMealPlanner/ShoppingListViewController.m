//
//  ViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 10.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "ShoppingListViewController.h"
#import "AppDelegate.h"
#import "PMPTableViewCell.h"
#import "AddShoppingItemViewController.h"

@interface ShoppingListViewController ()

@property(strong, nonatomic)
    NSFetchedResultsController *fetchedResultsController;
@property(weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlOutlet;
@property(strong, nonatomic) NSArray *itemCategories;

@end

@implementation ShoppingListViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  NSDictionary *dictionary =
      [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                     pathForResource:@"Info"
                                                              ofType:@"plist"]];
  self.itemCategories = [dictionary objectForKey:@"Item categories"];

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.managedObjectContext = appDelegate.managedObjectContext;

  [self reloadTableForSelectedSegment:self.segmentedControlOutlet
                                          .selectedSegmentIndex];
}

- (void)reloadTableForSelectedSegment:(NSInteger)index
{
  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"ShoppingItem"];

  NSString *category = self.itemCategories[index];

  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"%K == %@", @"category", category];

  [fetchRequest setPredicate:predicate];

  if (self.listSwitch.isOn)
    [fetchRequest setSortDescriptors:@[
      [NSSortDescriptor sortDescriptorWithKey:@"isChecked" ascending:YES],

      [NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES]
    ]];
  else
    [fetchRequest setSortDescriptors:@[
      [NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES]
    ]];

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

  [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - table view delegate

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  NSArray *sections = [self.fetchedResultsController sections];
  id<NSFetchedResultsSectionInfo> sectionInfo =
      [sections objectAtIndex:section];

  return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  PMPTableViewCell *cell = (PMPTableViewCell *)
      [self.tableView dequeueReusableCellWithIdentifier:@"ShoppingItemCell"
                                           forIndexPath:indexPath];

  // Configure Table View Cell
  [self configureCell:cell atIndexPath:indexPath];

  return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"showShoppingItem"]) {

    AddShoppingItemViewController *controller =
        (AddShoppingItemViewController *)[segue destinationViewController];

    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    NSManagedObject *object =
        [self.fetchedResultsController objectAtIndexPath:path];

    controller.shoppingItem = object;
    controller.editingExisting = YES;
  }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender
{
  if ([identifier isEqualToString:@"showShoppingItem"]) {
    if (self.listSwitch.isOn)
      return NO;
    else
      return YES;
  } else
    return YES;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.listSwitch.isOn) {
    // Fetch Record
    NSManagedObject *item =
        [self.fetchedResultsController objectAtIndexPath:indexPath];

    [item setValue:@(![[item valueForKey:@"isChecked"] boolValue])
            forKey:@"isChecked"];

    NSError *error = nil;

    //    [item.managedObjectContext save:&error];

    [self reloadTableForSelectedSegment:self.segmentedControlOutlet
                                            .selectedSegmentIndex];
  }
}

- (void)configureCell:(UITableViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath
{
  // Fetch Record
  NSManagedObject *item =
      [self.fetchedResultsController objectAtIndexPath:indexPath];

  PMPTableViewCell *PMPCell = (PMPTableViewCell *)cell;

  // Update Cell
  [PMPCell.itemNameLabel setText:[item valueForKey:@"itemName"]];
  [PMPCell.itemQuantityLabel
      setText:[[item valueForKey:@"quantity"] stringValue]];
  [PMPCell.itemUnitLabel setText:[item valueForKey:@"unit"]];

  if (self.listSwitch.isOn && [[item valueForKey:@"isChecked"] boolValue]) {
    PMPCell.itemNameLabel.textColor = [UIColor grayColor];
    PMPCell.itemQuantityLabel.textColor = [UIColor grayColor];
    PMPCell.itemUnitLabel.textColor = [UIColor grayColor];
  } else {
    PMPCell.itemNameLabel.textColor = [UIColor blackColor];
    PMPCell.itemQuantityLabel.textColor = [UIColor blackColor];
    PMPCell.itemUnitLabel.textColor = [UIColor blackColor];
  }
}

#pragma mark - fetched controller delegate

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
    [self configureCell:(PMPTableViewCell *)
                            [self.tableView cellForRowAtIndexPath:indexPath]
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

#pragma mark - shopping list switch

- (IBAction)shoppingListSwitchSwitched:(UISwitch *)sender
{
  if (sender.isOn) {
    [self.segmentedControlOutlet setEnabled:YES];

    [self reloadTableForSelectedSegment:self.segmentedControlOutlet
                                            .selectedSegmentIndex];
  } else {

    [self.segmentedControlOutlet setEnabled:NO];

    NSFetchRequest *fetchRequest =
        [[NSFetchRequest alloc] initWithEntityName:@"ShoppingItem"];

    [fetchRequest setSortDescriptors:@[
      [NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES]
    ]];

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

    [self.tableView reloadData];
  }
}

#pragma mark - segmented control

- (IBAction)segmentSelected:(UISegmentedControl *)sender
{
  [self reloadTableForSelectedSegment:sender.selectedSegmentIndex];
}

@end
