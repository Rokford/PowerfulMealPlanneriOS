//
//  CalendarViewController.h
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 31.08.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSCalendar.h"

@interface CalendarViewController
    : UIViewController <FSCalendarDelegate, FSCalendarDataSource>

@end
