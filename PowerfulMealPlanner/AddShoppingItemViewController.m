//
//  AddShoppingItemViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 12.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "AddShoppingItemViewController.h"
#import "AppDelegate.h"

@interface AddShoppingItemViewController ()

@property(nonatomic, strong) NSArray *pickerData;
@property(nonatomic, strong) NSManagedObjectContext *context;
@property(nonatomic, strong)
    NSFetchedResultsController *fetchedResultsController;

@end

@implementation AddShoppingItemViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.pickerData = @[
    @"Meat & fish",
    @"Dairy & bread",
    @"Fruits & vegetables",
    @"Cereals & spices",
    @"Tinned & frozen",
    @"Other"
  ];

  self.categoryPicker.delegate = self;
  self.categoryPicker.dataSource = self;

  [self.categoryPicker selectRow:self.pickerData.count - 1
                     inComponent:0
                        animated:YES];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)saveItem:(id)sender
{

  NSString *itemName = self.nameTextField.text;
  CGFloat itemQuantity = (CGFloat)[self.quantityTextField.text floatValue];
  NSString *itemUnit = self.unitTextField.text;
  NSString *category = [self.pickerData
      objectAtIndex:[self.categoryPicker selectedRowInComponent:0]];

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

    NSEntityDescription *entityDescription =
        [NSEntityDescription entityForName:@"ShoppingItem"
                    inManagedObjectContext:self.context];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];

    NSError *error = nil;

    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@", @"itemName",
                                         itemName, @"unit", itemUnit];
    [fetchRequest setPredicate:predicate];

    NSArray *resultsArray =
        [self.context executeFetchRequest:fetchRequest error:&error];

    if (!error && resultsArray.count > 0) {
      // there alread is such item
      NSManagedObject *item = resultsArray[0];

      CGFloat quantity = [[item valueForKey:@"quantity"] floatValue];
      quantity += itemQuantity;

      [item setValue:@(quantity) forKey:@"quantity"];

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

      if (![item.managedObjectContext save:&error]) {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", error, error.localizedDescription);
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

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return 0;
}

@end
