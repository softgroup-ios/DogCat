//
//  FullScreenVC.m
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "FullScreenVC.h"

@implementation FullScreenVC
- (instancetype)initWithImage: (UIImage*)image andBreedName: (NSString*)name {
    self = [super init];
    if (self) {
        self.image = image;
        self.name = name;
        self.view = [[UIImageView alloc] initWithImage:image];
        self.view.contentMode = UIViewContentModeScaleAspectFit;
        self.view.backgroundColor = [UIColor blackColor];
        self.view.userInteractionEnabled = YES;
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelFullImage:)];
    UIBarButtonItem* saveToGallery = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveToGallery:)];
    self.title = self.name;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveToGallery;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.hidesBarsOnTap = YES;
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown:)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipe];
}

#pragma mark - Actions

- (void) swipeDown: (UITapGestureRecognizer*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) cancelFullImage: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) saveToGallery: (UIBarButtonItem*)sender {
    UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:savedWithError:contextInfo:), nil);
}

- (void)image:(UIImage*)image savedWithError:(NSError*)error contextInfo:(void *)contextInfo {
    
    if (error || !image) {
        return;
    }
    
    //Info View
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 150.f, 100.f)];
    view.center = self.view.center;
    view.backgroundColor = [UIColor whiteColor];
    [view setAlpha:0.0f];
    view.layer.cornerRadius = 8.f;
    [self.view addSubview:view];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Saved";
    label.font = [UIFont systemFontOfSize:23.f];
    label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    [label sizeToFit];
    
    float xpos = (view.frame.size.width/2.0f) - (label.frame.size.width/2.0f);
    float ypos = (view.frame.size.height/2.0f) - (label.frame.size.height/2.0f);
    [label setFrame:CGRectMake(xpos, ypos, label.frame.size.width, label.frame.size.height)];
    [view addSubview:label];
    
    [UIView animateWithDuration:0.7f animations:^{
        [view setAlpha:0.85f];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            [view setAlpha:0.0f];
        }];
    }];
}

@end

