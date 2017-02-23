//
//  PickBreedsTableVCTableViewController.h
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SuccessPickBreedDelegate <NSObject>
- (void) pickBreed: (NSString*)name;
@end



@class GoogleImages;

@interface PickBreedsTableVC : UITableViewController <UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) GoogleImages *googleImage;
@property (weak, nonatomic) id <SuccessPickBreedDelegate> delegate;

@end

