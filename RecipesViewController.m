//
//  RecipesViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 26.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "RecipesViewController.h"
#import "AppDelegate.h"
#import "AddRecipeViewController.h"

@interface RecipesViewController ()

@property(strong, nonatomic)
    NSFetchedResultsController *fetchedResultsController;

@end

@implementation RecipesViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.managedObjectContext = appDelegate.managedObjectContext;

  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];

  [fetchRequest setSortDescriptors:@[
    [NSSortDescriptor sortDescriptorWithKey:@"recipeName" ascending:YES]
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

  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation
  // bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
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

- (void)configureCell:(UITableViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath
{
  NSManagedObject *recipe =
      [self.fetchedResultsController objectAtIndexPath:indexPath];

  cell.textLabel.text = [recipe valueForKey:@"recipeName"];
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
      [tableView dequeueReusableCellWithIdentifier:@"RecipeRow"
                                      forIndexPath:indexPath];

  [self configureCell:cell atIndexPath:indexPath];

  return cell;
}

- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NSManagedObject *record =
        [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (record) {
      [self.fetchedResultsController.managedObjectContext deleteObject:record];
    }
  }
}

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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  AddRecipeViewController *controller =
      (AddRecipeViewController *)[segue destinationViewController];

  NSIndexPath *path = [self.tableView indexPathForSelectedRow];
  NSManagedObject *object =
      [self.fetchedResultsController objectAtIndexPath:path];

  controller.recipeItem = object;
}

@end
