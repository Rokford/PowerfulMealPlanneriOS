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
#import "RecipesForCalendarTableViewController.h"

@interface CalendarViewController ()

@property(weak, nonatomic) IBOutlet FSCalendar *calendar;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic) NSMutableDictionary *thisMonthDaysWithRecipes;
@property(assign, nonatomic) BOOL inDaysSelectionMode;
@property(strong, nonatomic) NSDate *dateTapped;

@end

@implementation CalendarViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.thisMonthDaysWithRecipes = [[NSMutableDictionary alloc] init];

  AppDelegate *appDelegate =
      (AppDelegate *)[UIApplication sharedApplication].delegate;

  self.managedObjectContext = appDelegate.managedObjectContext;

  //  _calendar.appearance.todayColor = [UIColor clearColor];
  //  _calendar.appearance.titleTodayColor =
  //  _calendar.appearance.titleDefaultColor;
  //  _calendar.appearance.subtitleTodayColor =
  //      _calendar.appearance.subtitleDefaultColor;
}

- (void)viewWillAppear:(BOOL)animated
{
  NSDate *currentMonth = self.calendar.currentMonth;

  [self fetchAndSetRecipesForMonth:currentMonth];

  [self.calendar reloadData];

  //  [self.calendar setSelectedDate:[NSDate
  //  dateWithTimeIntervalSince1970:100]];

  //  [self.calendar setSelectedDate:nil];
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

#pragma mark - FSCalendar

- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date
{
  NSLog(@"sfsdf");
}

- (BOOL)calendar:(FSCalendar *)calendar shouldSelectDate:(NSDate *)date
{
  if (self.inDaysSelectionMode) {
    return true;
  } else {
    self.dateTapped = date;
    [self performSegueWithIdentifier:@"addRecipes" sender:self];
    return false;
  }
}

- (NSString *)calendar:(FSCalendar *)calendar subtitleForDate:(NSDate *)date
{
  NSCalendar *calendarHelper = [NSCalendar currentCalendar];

  for (NSDate *dateKey in self.thisMonthDaysWithRecipes) {
    if ([calendarHelper isDate:dateKey inSameDayAsDate:date]) {
      NSMutableSet *recipes =
          [self.thisMonthDaysWithRecipes objectForKey:dateKey];

      return [@(recipes.count) stringValue];
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
  return false;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  RecipesForCalendarTableViewController *controller =
      (RecipesForCalendarTableViewController *)
          [segue destinationViewController];
  controller.date = self.dateTapped;
}

@end
