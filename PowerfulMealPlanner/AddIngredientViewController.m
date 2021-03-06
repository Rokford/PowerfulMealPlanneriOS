//
//  AddIngredientViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 26.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "AddIngredientViewController.h"
#import "AppDelegate.h"
#import "CommonUnitCell.h"

@interface AddIngredientViewController ()

@property(nonatomic, strong) NSArray *pickerData;
@property(nonatomic, strong) NSManagedObjectContext *context;

@property(nonatomic, strong) NSArray *commonQuantites;
@property(nonatomic, strong) NSArray *commonUnits;

@end

@implementation AddIngredientViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  NSDictionary *dictionary =
      [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                     pathForResource:@"Info"
                                                              ofType:@"plist"]];
  self.pickerData = [dictionary objectForKey:@"Item categories"];

  self.picker.delegate = self;
  self.picker.dataSource = self;

  if (self.shoppingItem) {
    self.nameTextField.text = [self.shoppingItem valueForKey:@"itemName"];
    self.quantityTextField.text =
        [[self.shoppingItem valueForKey:@"quantity"] stringValue];
    self.unitTextField.text = [self.shoppingItem valueForKey:@"unit"];
    [self.picker
          selectRow:[self.pickerData indexOfObject:[self.shoppingItem
                                                       valueForKey:@"category"]]
        inComponent:0
           animated:YES];
  } else {

    [self.picker selectRow:self.pickerData.count - 1
               inComponent:0
                  animated:YES];
  }

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.context = appDelegate.managedObjectContext;

  NSFetchRequest *fetchRequest =
      [[NSFetchRequest alloc] initWithEntityName:@"Ingredient"];

  NSError *error = nil;

  NSArray *resultsArray =
      [self.context executeFetchRequest:fetchRequest error:&error];

  if (!error) {
    NSMutableDictionary *quantitiesDictionary =
        [[NSMutableDictionary alloc] init];
    NSMutableDictionary *unitsDictionary = [[NSMutableDictionary alloc] init];

    for (NSManagedObject *shoppingItem in resultsArray) {
      if ([quantitiesDictionary
              objectForKey:[shoppingItem valueForKey:@"quantity"]]) {
        NSInteger commonQuantityCounter = [[quantitiesDictionary
            objectForKey:[shoppingItem valueForKey:@"quantity"]] integerValue];
        commonQuantityCounter++;
        [quantitiesDictionary
            setObject:[NSNumber numberWithInteger:commonQuantityCounter]
               forKey:[shoppingItem valueForKey:@"quantity"]];
      } else {
        [quantitiesDictionary setObject:@(1)
                                 forKey:[shoppingItem valueForKey:@"quantity"]];
      }

      if ([unitsDictionary objectForKey:[shoppingItem valueForKey:@"unit"]]) {
        NSInteger commonQuantityCounter = [[unitsDictionary
            objectForKey:[shoppingItem valueForKey:@"unit"]] integerValue];
        commonQuantityCounter++;
        [unitsDictionary
            setObject:[NSNumber numberWithInteger:commonQuantityCounter]
               forKey:[shoppingItem valueForKey:@"unit"]];
      } else {
        [unitsDictionary setObject:@(1)
                            forKey:[shoppingItem valueForKey:@"unit"]];
      }
    }

    self.commonQuantites = [quantitiesDictionary
        keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
          if ([obj1 integerValue] > [obj2 integerValue]) {
            return NSOrderedAscending;
          } else {
            return NSOrderedDescending;
          }
        }];

    self.commonUnits = [unitsDictionary
        keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
          if ([obj1 integerValue] > [obj2 integerValue]) {
            return NSOrderedAscending;
          } else {
            return NSOrderedDescending;
          }
        }];
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

- (IBAction)saveItem:(id)sender
{

  NSString *itemName = self.nameTextField.text;
  CGFloat itemQuantity = (CGFloat)[self.quantityTextField.text floatValue];
  NSString *itemUnit = self.unitTextField.text;
  NSString *category =
      [self.pickerData objectAtIndex:[self.picker selectedRowInComponent:0]];

  if (![itemName length] || itemQuantity == 0 || ![itemUnit length]) {
    [[[UIAlertView alloc]
            initWithTitle:@"Fields cannot be empty"
                  message:@"Please provide name, quantity and unit"
                 delegate:self
        cancelButtonTitle:@"Dismiss"
        otherButtonTitles:nil, nil] show];
  } else {
    AppDelegate *appDelegate =
        (AppDelegate *)[UIApplication sharedApplication].delegate;

    self.context = appDelegate.managedObjectContext;

    NSError *error = nil;

    if (self.editingExisting) {
      [self.shoppingItem setValue:@(itemQuantity) forKey:@"quantity"];
      [self.shoppingItem setValue:itemUnit forKey:@"unit"];
      [self.shoppingItem setValue:itemName forKey:@"itemName"];
      [self.shoppingItem setValue:category forKey:@"category"];

      if (![self.shoppingItem.managedObjectContext save:&error]) {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", error, error.localizedDescription);
      }
    } else {

      NSEntityDescription *entityDescription =
          [NSEntityDescription entityForName:@"Ingredient"
                      inManagedObjectContext:self.context];

      NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
      [fetchRequest setEntity:entityDescription];

      NSPredicate *predicate =
          [NSPredicate predicateWithFormat:
                           @"%K == %@ AND %K == %@ AND recipe.recipeName == %@",
                           @"itemName", itemName, @"unit", itemUnit,
                           [self.recipe valueForKey:@"recipeName"]];
      [fetchRequest setPredicate:predicate];

      NSArray *resultsArray =
          [self.context executeFetchRequest:fetchRequest error:&error];

      if (!error && resultsArray.count > 0) {
        // there alread is such item
        NSManagedObject *item = resultsArray[0];

        CGFloat quantity = [[item valueForKey:@"quantity"] floatValue];
        quantity += itemQuantity;

        [item setValue:@(quantity) forKey:@"quantity"];

        [item setValue:itemUnit forKey:@"unit"];
        [item setValue:itemName forKey:@"itemName"];
        [item setValue:category forKey:@"category"];

        if (![item.managedObjectContext save:&error]) {
          NSLog(@"Unable to save managed object context.");
          NSLog(@"%@, %@", error, error.localizedDescription);
        }
      } else {
        // crate new item
        NSManagedObject *item =
            [[NSManagedObject alloc] initWithEntity:entityDescription
                     insertIntoManagedObjectContext:self.context];

        [item setValue:itemName forKey:@"itemName"];
        [item setValue:@(itemQuantity) forKey:@"quantity"];
        [item setValue:itemUnit forKey:@"unit"];
        [item setValue:category forKey:@"category"];

        //        [self.recipe setValue:[NSSet setWithObject:item]
        //        forKey:@"ingredients"];

        [item setValue:self.recipe forKey:@"recipe"];

        if (![item.managedObjectContext save:&error]) {
          NSLog(@"Unable to save managed object context.");
          NSLog(@"%@, %@", error, error.localizedDescription);
        }
      }
    }

    [[self navigationController] popViewControllerAnimated:YES];
  }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
  return self.pickerData.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
  return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
  return self.pickerData[row];
}

#pragma mark - table view

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.quantityTableView) {
    self.quantityTextField.text =
        [self.commonQuantites[indexPath.row] stringValue];

    [self.quantityTableView deselectRowAtIndexPath:indexPath animated:YES];
  } else {
    self.unitTextField.text = self.commonUnits[indexPath.row];
    [self.unitTableView deselectRowAtIndexPath:indexPath animated:YES];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.quantityTableView) {
    CommonUnitCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"CommonQuantity"];

    cell.label.text = [self.commonQuantites[indexPath.row] stringValue];

    return cell;
  } else {
    CommonUnitCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"CommonUnit"];
    cell.label.text = self.commonUnits[indexPath.row];

    return cell;
  }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.quantityTableView) {
    return self.commonQuantites.count;
  } else {
    return self.commonUnits.count;
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

@end
