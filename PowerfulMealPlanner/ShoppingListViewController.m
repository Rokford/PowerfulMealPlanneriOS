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

#pragma mark - segmented control

- (IBAction)segmentSelected:(UISegmentedControl *)sender
{
  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"ShoppingItem"];

  NSString *category = self.itemCategories[sender.selectedSegmentIndex];

  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"%K == %@", @"category", category];

  [fetchRequest setPredicate:predicate];

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

@end
