//
//  GoogleImages.m
//  Breeds
//
//  Created by admin on 26.10.16.
//  Copyright © 2016 sxsasha. All rights reserved.
//

#import "GoogleImages.h"




@interface GoogleImages () <UIWebViewDelegate>

@property (nonatomic,strong) UIWebView* webView;
@property (nonatomic,strong) NSString *searchRequest;
@property (nonatomic,assign) int startFrom;

@end

@implementation GoogleImages

NSString* const dogBreed = @"https://en.wikipedia.org/wiki/List_of_dog_breeds";
NSString* const catBreed = @"https://en.wikipedia.org/wiki/List_of_cat_breeds";

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isDogParseReady = NO;
        dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue,^{
            self.dogBreeds = [self downloadAndParseWikiPage:dogBreed forBreed:@"dog"];
            self.isDogParseReady = YES;
            [self.delegate parseReady:self.dogBreeds typeOf:Dog];
        });
        
        self.isCatParseReady = NO;
        dispatch_async(queue,^{
            self.catBreeds = [self downloadAndParseWikiPage:catBreed forBreed:@"cat"];
            self.isCatParseReady = YES;
            [self.delegate parseReady:self.catBreeds typeOf:Cat];
        });
        
        self.webView = [[UIWebView alloc]init];
        self.webView.delegate = self;
    }
    return self;
}

#pragma mark - API methods

- (void)searchImages:(NSString*)text {
    if (!text || [text isEqualToString:@""]) {
        [self.delegate foundImages:nil];
        return;
    }
    _startFrom = 0;
    self.searchRequest = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    [self loadGoogleImageFromText:self.searchRequest startFrom:self.startFrom];
}

- (void)searchMore {
    if (self.searchRequest) {
        _startFrom++;
        [self loadGoogleImageFromText:self.searchRequest startFrom:self.startFrom];
    }
}

#pragma mark - Work methods

- (NSArray*)searchGoogleImagesIn:(NSString*)allGooglePage {
    
    NSString *start = @"\\\"ou\\\":\\\""; //start \"ou\":\"
    NSString *end = @"\\\",\\\"ow\\\""; //end     \",\"ow\"
    
    NSMutableArray* array = [NSMutableArray array];
    NSRange nextRange = NSMakeRange(0, allGooglePage.length);
    while (nextRange.location < allGooglePage.length) {
        NSRange imageStartRange = [allGooglePage rangeOfString:start options:NSCaseInsensitiveSearch range:nextRange];
        if (imageStartRange.location==NSNotFound)
        {break;}
        
        NSRange nextStepRange = NSMakeRange(imageStartRange.location + imageStartRange.length, allGooglePage.length - (imageStartRange.location + imageStartRange.length) - 1);
        NSRange imageEndRange = [allGooglePage rangeOfString:end options:NSCaseInsensitiveSearch range:nextStepRange];
        
        if (nextStepRange.location==NSNotFound)
        {break;}
        
        NSRange imageRange = NSMakeRange(imageStartRange.location + imageStartRange.length, imageEndRange.location - (imageStartRange.location + imageStartRange.length));
        
        NSString* image = [allGooglePage substringWithRange:imageRange];
        image = [image stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        [array addObject:image];
        nextRange = NSMakeRange(imageEndRange.location, allGooglePage.length - imageEndRange.location - 1);
    }
    return array;
}

-(NSArray*)downloadAndParseWikiPage:(NSString*)wikiPage forBreed:(NSString*)breedType {
    
    NSMutableArray* array = [NSMutableArray array];
    NSURL* wikiPageURL = [NSURL URLWithString:wikiPage];
    
    NSError* error;
    NSString* allWikiPage = [NSString stringWithContentsOfURL:wikiPageURL encoding:NSUTF8StringEncoding error:&error];
    NSRange range = [allWikiPage rangeOfString:@"<th>Breed</th>" options:NSCaseInsensitiveSearch];
    
    if (range.location!=NSNotFound) {
        
        NSRange lastRange = NSMakeRange(range.location + range.length, allWikiPage.length - (range.location + range.length) - 1);
        NSRange allTableRange = [allWikiPage rangeOfString:@"</table>" options:NSCaseInsensitiveSearch range:lastRange];
        if (allTableRange.location!=NSNotFound){
            
            NSInteger startFrom = lastRange.location;
            while (startFrom < allTableRange.location) {
                
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
                if (![breed localizedCaseInsensitiveContainsString:breedType]) {
                    breed = [breed stringByAppendingFormat:@" %@",breedType];
                }
                [array addObject:breed];
                startFrom = breedRange.location + breedRange.length;
            }
        }
    }
    
    return array;
}

- (void) loadGoogleImageFromText:(NSString*)text startFrom:(int)startFrom {
    
  //  NSString* googlePage = [NSString stringWithFormat:@"https://www.google.com.ua/search?tbm=isch&q=%@",text];
    NSString* googlePage = [NSString stringWithFormat:@"https://www.google.com.ua/search?&client=safari&yv=2&q=%@&start=%d00&asearch=ichunk&tbm=isch&ijn=%d",text,startFrom,startFrom];
    
    NSURL* googlePageURL = [NSURL URLWithString:googlePage];
    
    NSURLRequest* googleImageRequest = [NSURLRequest requestWithURL:googlePageURL];
    [self.webView loadRequest:googleImageRequest];
}

- (void) getHTMLFromSite {
    
    NSString* javaScriptCode = @"document.getElementsByTagName('html')[0].innerHTML";
    
    NSString *allGooglePage = [self.webView stringByEvaluatingJavaScriptFromString:javaScriptCode];
    NSArray *array = [self searchGoogleImagesIn:allGooglePage];
    
    [self.delegate foundImages:array];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self getHTMLFromSite];
}

@end
