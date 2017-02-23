//
//  BreedCollectionView.m
//  BreedFinder
//
//  Created by sxsasha on 21.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "BreedCollectionView.h"
#import "GoogleImages.h"
#import "BreedCell.h"
#import "GreedoCollectionViewLayout.h"
#import "FullScreenVC.h"
#import "PickBreedsTableVC.h"




typedef void (^SuccessDownloadPhoto)(UIImage* image);










@interface BreedCollectionView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GreedoCollectionViewLayoutDataSource, SuccessPickBreedDelegate>

@property (nonatomic,strong) NSMutableArray <UIImage*>* images;
@property (nonatomic,strong) GoogleImages* googleImage;
@property (nonatomic,strong) UIPickerView* pickerView;
@property (strong, nonatomic) GreedoCollectionViewLayout *collectionViewSizeCalculator;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;

@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout *flowLayout;

@end


@implementation BreedCollectionView

static NSString * const reuseIdentifier = @"BreedImage";


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataAndCollectionView];
}

- (void) initDataAndCollectionView {
    
    self.googleImage = [[GoogleImages alloc]init];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.collectionViewSizeCalculator = [[GreedoCollectionViewLayout alloc] initWithCollectionView:self.collectionView];
    self.collectionViewSizeCalculator.dataSource = self;
    self.collectionViewSizeCalculator.rowMaximumHeight = CGRectGetHeight(self.collectionView.bounds) / 3;
    self.collectionViewSizeCalculator.fixedHeight = NO;
    
    //work with collection layout
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.minimumLineSpacing = 5;
    flowLayout.minimumInteritemSpacing = 5;
    
    CGFloat windowWidth =  [UIApplication sharedApplication].windows.firstObject.frame.size.width;
    flowLayout.itemSize = CGSizeMake(windowWidth/4, windowWidth/4);
    flowLayout.headerReferenceSize = CGSizeZero;
    flowLayout.footerReferenceSize = CGSizeZero;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    //download spinner
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.collectionView.bounds.size.width / 2, self.collectionView.bounds.size.height / 2);
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
}

#pragma mark - Load All Image

-(void) generateAllImage: (NSArray <NSString*>*)imagesURLs
{
    for (NSString* imageString in imagesURLs)
    {
        [self downloadImage:imageString successBlock:^(UIImage *image) {
            if (image) {
                @synchronized (self.images) {
                    [self.images addObject:image];
                    if (self.images.count % 2 == 0) {
                        [self.collectionView reloadData];
                    }
                }
            }
        }];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

#pragma mark  Download Image

- (void) downloadImage: (NSString*) urlString
          successBlock: (SuccessDownloadPhoto) successBlock {
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!data||error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(nil);
            });
            return;
        }
        
        UIImage *image = [[UIImage alloc]initWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(image);
        });
    }] resume];
}

#pragma mark - GreedoCollectionViewLayoutDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.collectionViewSizeCalculator sizeForPhotoAtIndexPath:indexPath];
}

- (CGSize)greedoCollectionViewLayout:(GreedoCollectionViewLayout *)layout originalImageSizeAtIndexPath:(NSIndexPath *)indexPath
{
    // Return the image size to GreedoCollectionViewLayout
    if (indexPath.item < self.images.count) {
        UIImage *image = [self.images objectAtIndex:indexPath.item];
        return image.size;
    }
    
    NSLog(@"indexPath: %ld %ld",indexPath.item,self.images.count);
    
    return CGSizeMake(0.1, 0.1);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BreedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    UIImage* image = [self.images objectAtIndex:indexPath.row];
    cell.imageView.image = image;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark Menu Action

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    return action == NSSelectorFromString(@"copy:");
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    if (action == @selector(copy:)) {
        UIImage *image = [self.images objectAtIndex:indexPath.item];
        [UIPasteboard generalPasteboard].image = image;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIImage *image = [self.images objectAtIndex:indexPath.item];
    [self openImageFullScreen:image];
}

#pragma mark - Open Image

- (void) openImageFullScreen: (UIImage*) image {
    FullScreenVC *imageFullScreen = [[FullScreenVC alloc]initWithImage:image andBreedName:self.title];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imageFullScreen];
    
    [self presentViewController:nav animated:NO completion:nil];
}

#pragma mark - Select Breed Action

- (IBAction)showPopout:(UIBarButtonItem *)sender
{
    PickBreedsTableVC *pickTVC = [[PickBreedsTableVC alloc] init];
    pickTVC.googleImage = self.googleImage;
    pickTVC.delegate = self;
    pickTVC.title = @"Pick a breed";
    
    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:pickTVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void) pickBreed: (NSString*)name {
    
    self.title = name;
    self.images = [NSMutableArray array];
    [self.collectionView reloadData];
    [self.collectionViewSizeCalculator clearCache];
    
    //start download spinner
    [self.spinner startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.googleImage searchImages:name finishBlock:^(NSArray *arrayOfImages) {
        [self.spinner stopAnimating];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self generateAllImage: arrayOfImages];
    }];
}
@end
