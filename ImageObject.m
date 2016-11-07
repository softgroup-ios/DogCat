//
//  ImageObject.m
//  SuperImageTableView
//
//  Created by admin on 26.10.16.
//  Copyright © 2016 admin. All rights reserved.
//

#import "ImageObject.h"

@implementation ImageObject

- (instancetype)initWithImageURL : (NSString*) url andNumberOfbreed: (NSInteger) picker
{
    self = [super init];
    if (self)
    {
        NSURL* urlImage = [NSURL URLWithString:url];
        self.numberOfBreed = picker;
        NSError* error;
        NSData* dataImage;
        if (urlImage)
        {
            dataImage = [NSData dataWithContentsOfURL:urlImage options:NSDataReadingMappedAlways error:&error];
            
            if ((!error)&&(dataImage))
            {self.image = [UIImage imageWithData:dataImage];}
            else
            {
                dataImage = nil;
                return nil;
            }
        }
        else
        {return nil;}
    }
    return self;
}

@end
