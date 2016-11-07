//
//  ImageObject.h
//  SuperImageTableView
//
//  Created by admin on 26.10.16.
//  Copyright © 2016 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageObject : NSObject

@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) UIImage* image;
@property (nonatomic,assign) NSInteger numberOfBreed;

- (instancetype)initWithImageURL : (NSString*) url andNumberOfbreed: (NSInteger) picker;

@end
