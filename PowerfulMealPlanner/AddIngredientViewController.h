//
//  AddIngredientViewController.h
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 26.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AddIngredientViewController
    : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource,
                        UITableViewDataSource, UITableViewDelegate>

@property(weak, nonatomic) IBOutlet UITextField *nameTextField;
@property(weak, nonatomic) IBOutlet UITextField *quantityTextField;
@property(weak, nonatomic) IBOutlet UITextField *unitTextField;
@property(weak, nonatomic) IBOutlet UIPickerView *picker;
@property(weak, nonatomic) IBOutlet UITableView *quantityTableView;
@property(weak, nonatomic) IBOutlet UITableView *unitTableView;

@property(strong, nonatomic) NSManagedObject *shoppingItem;
@property(strong, nonatomic) NSManagedObject *recipe;
@property(assign, nonatomic) BOOL editingExisting;

@end
