//
//  GoogleImages.h
//  Breeds
//
//  Created by admin on 26.10.16.
//  Copyright © 2016 sxsasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GoogleImages : NSObject

@property (nonatomic,strong) NSArray* arrayOfBreeds;

- (void) searchImages: (NSString*) text afterBlock: (void(^)(NSArray* array)) block;
@end
