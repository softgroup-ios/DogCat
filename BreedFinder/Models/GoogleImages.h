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

@property (strong, nonatomic) NSArray* arrayOfBreeds;
@property (assign, nonatomic) BOOL isParse;

@property (copy, nonatomic) void(^imagesReady)(NSArray* array);

- (void) searchImages: (NSString*)text
          finishBlock: (void(^)(NSArray* array))finishBlock;
@end
