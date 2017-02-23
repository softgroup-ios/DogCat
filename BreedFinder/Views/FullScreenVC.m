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

- (void) cancelFullImage: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) saveToGallery: (UIBarButtonItem*) sender {
    UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
}
@end

