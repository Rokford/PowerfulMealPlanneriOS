//
//  HelpViewController.m
//  PowerfulMealPlanner
//
//  Created by PLGRIZW on 04.09.2015.
//  Copyright (c) 2015 Mobinaut. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@property(weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property(strong, nonatomic) NSArray *helpImages;
@property(strong, nonatomic) NSArray *helpTexts;
@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UILabel *textLabel;

@property(assign, nonatomic) int imageCounter;

@end

@implementation HelpViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.helpImages = [[NSBundle mainBundle] pathsForResourcesOfType:@"png"
                                                       inDirectory:@"Help"];

  NSString *plistPath =
      [[NSBundle mainBundle] pathForResource:@"help" ofType:@"plist"];
  self.helpTexts = [NSArray arrayWithContentsOfFile:plistPath];

  self.imageView.contentMode = UIViewContentModeScaleAspectFit;

  self.pageControl.numberOfPages = self.helpImages.count;
  [self.pageControl setCurrentPage:self.imageCounter];

  [self.imageView
      setImage:[UIImage
                   imageWithContentsOfFile:self.helpImages[self.imageCounter]]];

  self.textLabel.text = self.helpTexts[0];
}

- (IBAction)swipeRight:(id)sender
{
  if (self.imageCounter > 0) {
    self.imageCounter--;
    [self.pageControl setCurrentPage:self.imageCounter];
    self.textLabel.text = self.helpTexts[self.imageCounter];

    [UIView transitionWithView:self.imageView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      [self.imageView
                          setImage:[UIImage
                                       imageWithContentsOfFile:
                                           self.helpImages[self.imageCounter]]];
                    }
                    completion:NULL];
  }
}
- (IBAction)swipeLeft:(id)sender
{
  if (self.imageCounter < self.helpImages.count - 1) {
    self.imageCounter++;
    [self.pageControl setCurrentPage:self.imageCounter];
    self.textLabel.text = self.helpTexts[self.imageCounter];

    [UIView transitionWithView:self.imageView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      [self.imageView
                          setImage:[UIImage
                                       imageWithContentsOfFile:
                                           self.helpImages[self.imageCounter]]];
                    }
                    completion:NULL];
  }
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

@end
