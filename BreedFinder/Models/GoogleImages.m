//
//  GoogleImages.m
//  Breeds
//
//  Created by admin on 26.10.16.
//  Copyright © 2016 sxsasha. All rights reserved.
//

#import "GoogleImages.h"

@interface GoogleImages () <UIWebViewDelegate>


@property (nonatomic,strong) NSArray* arrayOfCurrentImages;
@property (nonatomic,strong,nullable) void(^afterBlock)(NSArray*);
@property (nonatomic,strong) UIWebView* webView;
@property (nonatomic,strong) NSString* allGooglePage;

@property (nonatomic,assign) BOOL isParse;
@end

@implementation GoogleImages

#pragma mark - Help methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.isParse = NO;
        dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue,^{
            self.arrayOfBreeds = [self downloadAndParseWikiPage];
            self.isParse = YES;
            self.allGooglePage = nil;
        });
    }
    return self;
}

- (void) searchImages: (NSString*) text afterBlock: (void(^)(NSArray*)) block
{
    NSArray* arrayOfStrings = [text componentsSeparatedByString:@" "];
    NSString* searchText = [arrayOfStrings componentsJoinedByString:@"+"];
    [self loadGoogleImageFromText:searchText];
    self.afterBlock = block;
}

-(NSArray*) searchGoogleImagesInCurrentHTML
{
    NSMutableArray* array = [NSMutableArray array];
    NSRange nextRange = NSMakeRange(0, self.allGooglePage.length);
    while (nextRange.location < self.allGooglePage.length)
    {
        NSRange imageStartRange = [self.allGooglePage rangeOfString:@"\"ou\":\"" options:NSCaseInsensitiveSearch range:nextRange];
        
        if (imageStartRange.location==NSNotFound)
        {break;}
        
        NSRange nextStepRange = NSMakeRange(imageStartRange.location + imageStartRange.length, self.allGooglePage.length - (imageStartRange.location + imageStartRange.length) - 1);
        NSRange imageEndRange = [self.allGooglePage rangeOfString:@"\",\"ow\"" options:NSCaseInsensitiveSearch range:nextStepRange];
        
        if (nextStepRange.location==NSNotFound)
        {break;}
        
        NSRange imageRange = NSMakeRange(imageStartRange.location + imageStartRange.length, imageEndRange.location - (imageStartRange.location + imageStartRange.length));
        
        NSString* image = [self.allGooglePage substringWithRange:imageRange];
        [array addObject:image];
        
        nextRange = NSMakeRange(imageEndRange.location, self.allGooglePage.length - imageEndRange.location - 1);
    }
    //"ou":"   \"ou\":\"
    //","ow"  \",\"ow\"
    return array;
}

-(NSArray*) downloadAndParseWikiPage
{
    NSMutableArray* array = [NSMutableArray array];
    NSString* wikiPage = @"https://en.wikipedia.org/wiki/List_of_dog_breeds"; //List_of_cat_breeds List_of_dog_breeds
    NSURL* wikiPageURL = [NSURL URLWithString:wikiPage];
    
    NSError* error;
    NSString* allWikiPage = [NSString stringWithContentsOfURL:wikiPageURL encoding:NSUTF8StringEncoding error:&error];
    NSRange range = [allWikiPage rangeOfString:@"<th>Breed</th>" options:NSCaseInsensitiveSearch];
    
    if (range.location!=NSNotFound)
    {
        NSRange lastRange = NSMakeRange(range.location + range.length, allWikiPage.length - (range.location + range.length) - 1);
        NSRange allTableRange = [allWikiPage rangeOfString:@"</table>" options:NSCaseInsensitiveSearch range:lastRange];
        if (allTableRange.location!=NSNotFound)
        {
            long long startFrom = lastRange.location;
            while (startFrom < allTableRange.location)
            {
                NSRange searchRange = NSMakeRange(startFrom, allWikiPage.length - startFrom - 1);
                NSRange trRange = [allWikiPage rangeOfString:@"<tr>" options:NSCaseInsensitiveSearch range:searchRange];
                if ((trRange.location==NSNotFound)||(trRange.location > allTableRange.location))
                {break;}
                
                NSRange searchBreedRange = NSMakeRange(trRange.location, allWikiPage.length - trRange.location - 1);
                NSRange startBreedRange = [allWikiPage rangeOfString:@"title=\"" options:NSCaseInsensitiveSearch range:searchBreedRange];
                if (startBreedRange.location==NSNotFound)
                {break;}
                
                NSRange searchEndRange = NSMakeRange(startBreedRange.location + startBreedRange.length, allWikiPage.length - (startBreedRange.location + startBreedRange.length) - 1);
                NSRange endBreedRange = [allWikiPage rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:searchEndRange];
                if (endBreedRange.location==NSNotFound)
                {break;}
                
                NSRange breedRange = NSMakeRange(startBreedRange.location + startBreedRange.length, endBreedRange.location - (startBreedRange.location + startBreedRange.length));
                NSString* breed = [allWikiPage substringWithRange:breedRange];
                [array addObject:breed];
                startFrom = breedRange.location + breedRange.length;
            }
        }
        
    }
    return array;
}

- (void) loadGoogleImageFromText: (NSString*) text
{
    NSString* googlePage = [NSString stringWithFormat:@"https://www.google.com.ua/search?tbm=isch&q=%@",text];
    NSURL* googlePageURL = [NSURL URLWithString:googlePage];
    
    NSURLRequest* googleImageRequest = [NSURLRequest requestWithURL:googlePageURL];
    self.webView = [[UIWebView alloc]init];
    self.webView.delegate = self;
    [self.webView loadRequest:googleImageRequest];
}

- (void) getHTMLFromSite
{
    NSString* javaScriptCode = @"document.getElementsByTagName('html')[0].innerHTML";
    
    self.allGooglePage = [self.webView stringByEvaluatingJavaScriptFromString:javaScriptCode];
    
    self.afterBlock([self searchGoogleImagesInCurrentHTML]);
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self getHTMLFromSite];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}
@end
