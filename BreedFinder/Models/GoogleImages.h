//
//  GoogleImages.h
//  Breeds
//
//  Created by admin on 26.10.16.
//  Copyright © 2016 sxsasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    Cat,
    Dog
} TypeOfBreed;


@protocol SearchImagesDelegate <NSObject>
- (void) foundImages: (NSArray <NSString*>*)images;
- (void) parseReady: (NSArray <NSString*>*)breeds
             typeOf: (TypeOfBreed) typeOfBreed;
@end



@interface GoogleImages : NSObject

@property (strong, nonatomic) NSArray* dogBreeds;
@property (strong, nonatomic) NSArray* catBreeds;
@property (assign, nonatomic) BOOL isCatParseReady;
@property (assign, nonatomic) BOOL isDogParseReady;

@property (weak, nonatomic) id <SearchImagesDelegate> delegate;


- (void) searchImages: (NSString*)text;
- (void) searchMore;
@end
