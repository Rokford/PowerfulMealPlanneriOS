//
//  AddShoppingItemViewController.h
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 12.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AddShoppingItemViewController
    : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource,
                        UITableViewDataSource, UITableViewDelegate,
                        UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UITextField *nameTextField;
@property(weak, nonatomic) IBOutlet UITextField *quantityTextField;
@property(weak, nonatomic) IBOutlet UITextField *unitTextField;
@property(weak, nonatomic) IBOutlet UITableView *commonUnitsTableView;
@property(weak, nonatomic) IBOutlet UIPickerView *categoryPicker;

@property(strong, nonatomic) NSManagedObject *shoppingItem;
@property(assign, nonatomic) BOOL editingExisting;

@end
