//
//  AddRecipeViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 26.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "AddRecipeViewController.h"
#import "PMPTableViewCell.h"
#import "AppDelegate.h"
#import "AddIngredientViewController.h"

@interface AddRecipeViewController ()

@property(weak, nonatomic) IBOutlet UITextField *nameTextField;
@property(weak, nonatomic) IBOutlet UITableView *ingredientsTableVIew;
@property(strong, nonatomic) NSString *oldName;
@property(nonatomic, strong) NSArray *ingredientsArray;
@property(strong, nonatomic)
    NSFetchedResultsController *fetchedResultsController;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButton;

@end

@implementation AddRecipeViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.managedObjectContext = appDelegate.managedObjectContext;

  if (self.recipeItem) {

    self.nameTextField.text = [self.recipeItem valueForKey:@"recipeName"];

    NSFetchRequest *fetchRequest =
        [[NSFetchRequest alloc] initWithEntityName:@"Ingredient"];

    NSPredicate *predicate = [NSPredicate
        predicateWithFormat:@"recipe.recipeName LIKE %@",
                            [self.recipeItem valueForKey:@"recipeName"]];

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
  }
}

- (IBAction)saveRecipe:(id)sender
{
  if (self.nameTextField.text.length > 0 && self.recipeItem) {
    NSError *error = nil;
    NSFetchRequest *fetchRequest =
        [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];

    NSPredicate *predicate = [NSPredicate
        predicateWithFormat:@"recipeName LIKE %@", self.nameTextField.text];

    [fetchRequest setPredicate:predicate];

    NSArray *resultsArray =
        [self.managedObjectContext executeFetchRequest:fetchRequest
                                                 error:&error];

    if (!error) {

      if (resultsArray.count == 0 ||
          (resultsArray.count == 1 &&
           [((NSManagedObject *)resultsArray[0])
                   .objectID isEqual:self.recipeItem.objectID])) {
        [self.recipeItem setValue:self.nameTextField.text forKey:@"recipeName"];

        if (![self.recipeItem.managedObjectContext save:&error]) {
          NSLog(@"Unable to save managed object context.");
          NSLog(@"%@, %@", error, error.localizedDescription);
        }

        [[self navigationController] popViewControllerAnimated:YES];
      } else {

        [[[UIAlertView alloc]
                initWithTitle:@"Duplicate recipe name"
                      message:@"A recipe with the same name already exists"
                     delegate:self
            cancelButtonTitle:@"Dismiss"
            otherButtonTitles:nil, nil] show];
      }
    }

  } else {

    NSString *message = @"";

    if (!self.recipeItem && self.nameTextField.text.length == 0)
      message = @"Please provide a name and at least one ingredient";
    else if (!self.recipeItem)
      message = @"Please add at least one ingredient";
    else
      message = @"Please provide a name for this recipe";

    [[[UIAlertView alloc] initWithTitle:@"Cannot save"
                                message:message
                               delegate:self
                      cancelButtonTitle:@"Dismiss"
                      otherButtonTitles:nil, nil] show];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];

  return YES;
}

#pragma mark - navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender
{
  if ([identifier isEqualToString:@"newIngredient"]) {
    if (![self.nameTextField.text length]) {

      [[[UIAlertView alloc] initWithTitle:@"Name missing"
                                  message:@"Please provide a name for this "
                                  @"recipe before adding any ingredients"
                                 delegate:self
                        cancelButtonTitle:@"Dismiss"
                        otherButtonTitles:nil, nil] show];
      return NO;
    } else {
      NSFetchRequest *fetchRequest =
          [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];

      NSPredicate *predicate = [NSPredicate
          predicateWithFormat:@"recipeName LIKE %@", self.nameTextField.text];

      [fetchRequest setPredicate:predicate];

      NSError *error;

      NSArray *resultsArray =
          [self.managedObjectContext executeFetchRequest:fetchRequest
                                                   error:&error];

      if (!error && (resultsArray.count == 0 ||
                     (resultsArray.count == 1 &&
                      [((NSManagedObject *)resultsArray[0])
                              .objectID isEqual:self.recipeItem.objectID]))) {
        return YES;
      } else {
        [[[UIAlertView alloc]
                initWithTitle:@"Duplicate recipe name"
                      message:@"A recipe with the same name already exists"
                     delegate:self
            cancelButtonTitle:@"Dismiss"
            otherButtonTitles:nil, nil] show];
        return NO;
      }
    }
  } else {
    return YES;
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  AddIngredientViewController *controller =
      (AddIngredientViewController *)[segue destinationViewController];

  if ([segue.identifier isEqualToString:@"newIngredient"]) {
    if (!self.recipeItem) {
      NSEntityDescription *entityDescription =
          [NSEntityDescription entityForName:@"Recipe"
                      inManagedObjectContext:self.managedObjectContext];

      NSManagedObject *item =
          [[NSManagedObject alloc] initWithEntity:entityDescription
                   insertIntoManagedObjectContext:self.managedObjectContext];

      [item setValue:self.nameTextField.text forKey:@"recipeName"];

      NSError *error = nil;

      if (![item.managedObjectContext save:&error]) {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", error, error.localizedDescription);
      }

      self.recipeItem = item;

      NSFetchRequest *fetchRequest =
          [[NSFetchRequest alloc] initWithEntityName:@"Ingredient"];

      NSPredicate *predicate = [NSPredicate
          predicateWithFormat:@"recipe.recipeName LIKE %@",
                              [self.recipeItem valueForKey:@"recipeName"]];

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

      error = nil;
      [self.fetchedResultsController performFetch:&error];

      if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
      }

      [self.ingredientsTableVIew reloadData];
    }
  }

  if ([segue.identifier isEqualToString:@"editIngredient"]) {

    NSIndexPath *path = [self.ingredientsTableVIew indexPathForSelectedRow];
    NSManagedObject *object =
        [self.fetchedResultsController objectAtIndexPath:path];

    [self.ingredientsTableVIew deselectRowAtIndexPath:path animated:YES];

    controller.shoppingItem = object;

    controller.editingExisting = YES;
  }

  controller.recipe = self.recipeItem;
}

#pragma mark - fetched controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  [self.ingredientsTableVIew beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  [self.ingredientsTableVIew endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
  switch (type) {
  case NSFetchedResultsChangeInsert: {
    [self.ingredientsTableVIew
        insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  case NSFetchedResultsChangeDelete: {
    [self.ingredientsTableVIew
        deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  case NSFetchedResultsChangeUpdate: {
    [self configureCell:(PMPTableViewCell *)[self.ingredientsTableVIew
                            cellForRowAtIndexPath:indexPath]
            atIndexPath:indexPath];
    break;
  }
  case NSFetchedResultsChangeMove: {
    [self.ingredientsTableVIew
        deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    [self.ingredientsTableVIew
        insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
              withRowAnimation:UITableViewRowAnimationFade];
    break;
  }
  }
}

#pragma mark - table view

- (void)configureCell:(PMPTableViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath
{
  NSManagedObject *item =
      [self.fetchedResultsController objectAtIndexPath:indexPath];

  [cell.itemNameLabel setText:[item valueForKey:@"itemName"]];
  [cell.itemQuantityLabel setText:[[item valueForKey:@"quantity"] stringValue]];
  [cell.itemUnitLabel setText:[item valueForKey:@"unit"]];
}

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
  PMPTableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"IngredientCell"
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
    if ([self.ingredientsTableVIew numberOfRowsInSection:0] > 1) {
      NSManagedObject *record =
          [self.fetchedResultsController objectAtIndexPath:indexPath];

      if (record) {
        [self.fetchedResultsController.managedObjectContext
            deleteObject:record];
      }
    } else {
      [[[UIAlertView alloc]
              initWithTitle:@"Ingredients"
                    message:@"Recipe cannot have no ingredients assigned"
                   delegate:self
          cancelButtonTitle:@"Dismiss"
          otherButtonTitles:nil, nil] show];
    }
  }
}

@end
