//
//  GoogleImages.h
//  Breeds
//
//  Created by admin on 26.10.16.
//  Copyright © 2016 sxsasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@protocol SearchImagesDelegate <NSObject>
- (void) foundImages: (NSArray <NSString*>*)images;
- (void) parseReady: (NSArray <NSString*>*)breeds
             typeOf: (NSInteger) typeOfBreed;
@end



@interface GoogleImages : NSObject

@property (strong, nonatomic) NSArray* dogBreeds;
@property (strong, nonatomic) NSArray* catBreeds;
@property (assign, nonatomic) BOOL isCatParseReady;
@property (assign, nonatomic) BOOL isDogParseReady;

@property (weak, nonatomic) id <SearchImagesDelegate> delegate;


- (void) searchImages: (NSString*)text;
@end
