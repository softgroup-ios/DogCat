//
//  PickBreedsTableVCTableViewController.h
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleImages.h"




@protocol SuccessPickBreedDelegate <NSObject>
- (void) searchImage: (NSString*)name;
@end



@class GoogleImages;

@interface PickBreedsTableVC : UITableViewController

@property (strong, nonatomic) NSArray <NSString*> *listOfBreeds;
@property (assign, nonatomic) TypeOfBreed typeOfBreed;
@property (weak, nonatomic) id <SuccessPickBreedDelegate> delegate;

@end

