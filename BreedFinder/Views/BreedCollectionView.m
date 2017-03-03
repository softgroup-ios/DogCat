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

#define ARC4RANDOM_MAX      0x100000000


typedef void (^SuccessDownloadPhoto)(UIImage* image);






@interface BreedCollectionView () <UINavigationControllerDelegate ,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,NSURLSessionTaskDelegate, GreedoCollectionViewLayoutDataSource, SuccessPickBreedDelegate, SearchImagesDelegate>

@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (nonatomic,strong) NSMutableArray <UIImage*>* sourceImages;
@property (nonatomic,strong) NSMutableArray <UIImage*>* showImages;
@property (nonatomic,strong) NSMutableArray <NSURLSessionDataTask*>* downloadTasks;
//@property (nonatomic,strong) NSMutableDictionary *sizeCache;
@property (nonatomic,assign) int countOfDataTask;

@property (nonatomic,strong) NSString* searchName;
@property (nonatomic,strong) GoogleImages* googleImage;
@property (weak, nonatomic) PickBreedsTableVC *pickTVC;

@property (strong, nonatomic) GreedoCollectionViewLayout *collectionViewSizeCalculator;

@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (assign, nonatomic) BOOL hideStatusBar;
//@property (assign, nonatomic) BOOL firstItem;

@end


@implementation BreedCollectionView

static NSString * const reuseIdentifier = @"BreedImage";


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataAndCollectionView];
}

- (void) initDataAndCollectionView {
    self.googleImage = [[GoogleImages alloc]init];
    self.googleImage.delegate = self;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.navigationController.delegate = self;
    
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
    
    self.navigationController.hidesBarsOnSwipe = NO;
    [self.navigationController.barHideOnSwipeGestureRecognizer addTarget:self action:@selector(swipe:)];
}

- (void) setupTitle: (NSString*)text {
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, 40)];
    titleLabel.text = text;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.numberOfLines = 0;
    titleLabel.adjustsFontSizeToFitWidth = YES; // As alternative you can also make it multi-line.
    titleLabel.minimumScaleFactor = 0.5;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = titleLabel;
}

#pragma mark - Go to Landscape

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    
    if (self.view.frame.size.width != size.width) {
        self.spinner.center = CGPointMake(size.width / 2, size.height / 2);
        [self.collectionViewSizeCalculator clearCache];
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self.collectionView reloadData];
        } completion:nil];
        
        if (!(self.isViewLoaded && self.view.window)) {
            [self.collectionView reloadData];
        }
    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    return [self supportedInterfaceOrientations];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Status Bar hidden

- (void) swipe: (UIGestureRecognizer*) swipeRecognizer {
    
    BOOL shouldHideStatusBar = self.navigationController.navigationBar.frame.origin.y < 0;
    self.hideStatusBar = shouldHideStatusBar;
    
    [UIView animateWithDuration:0.2 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (BOOL)prefersStatusBarHidden {
    return self.hideStatusBar;
}

#pragma mark - Download Image & Load All Image

- (void)generateAllImage:(NSArray <NSString*>*)imagesURLs {
    for (NSString* imageString in imagesURLs)
    {
        [self downloadImage:imageString successBlock:^(UIImage *image) {
            if (image) {
                [self prepareToShow:image compitionBlock:^(UIImage *image) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self addNewCell:image];
                        self.navigationController.hidesBarsOnSwipe = YES;
                        [self.spinner stopAnimating];
                    });
                }];
            }
        }];
    }
}

- (void)prepareToShow:(UIImage*)image
        compitionBlock:(void (^)(UIImage *image))compitionBlock {
    
    [self.sourceImages addObject:image];
     NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.sourceImages.count-1 inSection:0];
    CGSize imageSize = [self.collectionViewSizeCalculator sizeForPhotoAtIndexPath:indexPath];
    UIImage *resizeImage = [self imageWithImage:image scaledToSize:imageSize];
    compitionBlock(resizeImage);
}

- (void)addNewCell: (UIImage*)image {
    [self.collectionView performBatchUpdates:^{
        [self.showImages addObject:image];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.showImages.count-1 inSection:0];
        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    }
    completion:nil];
}

- (void)downloadImage:(NSString*)urlString
         successBlock:(SuccessDownloadPhoto)successBlock {

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        self.countOfDataTask--;
        if (!data||error) {
            successBlock(nil);
            return;
        }
        
        UIImage *image = [[UIImage alloc]initWithData:data];
        successBlock(image);
    }];
    [task resume];
    [self.downloadTasks addObject:task];
    self.countOfDataTask++;
}

- (void) setCountOfDataTask:(int)countOfDataTask {
    _countOfDataTask = countOfDataTask;
    if (!countOfDataTask) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

#pragma mark - GreedoCollectionViewLayoutDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.collectionViewSizeCalculator sizeForPhotoAtIndexPath:indexPath];
}

- (CGSize)greedoCollectionViewLayout:(GreedoCollectionViewLayout *)layout originalImageSizeAtIndexPath:(NSIndexPath *)indexPath  {
    if (indexPath.item < self.sourceImages.count) {
        UIImage *image = [self.sourceImages objectAtIndex:indexPath.item];
        return image.size;
    }
    
    return CGSizeMake(0.1, 0.1);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.showImages count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BreedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.imageView.image = [self.showImages objectAtIndex:indexPath.row];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    return cell;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)toSize {
    
    CGFloat imageScale = image.size.height/image.size.width;
    CGFloat toSizeScale = toSize.height/toSize.width;
    
    CGSize newSize = toSize;
    if (imageScale != toSizeScale) {
        if (toSize.height > toSize.width) {
            newSize = CGSizeMake(toSize.height / imageScale, toSize.height);
        }
        else {
            newSize = CGSizeMake(toSize.width, toSize.width * imageScale);
        }
    }
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Copy Action

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    return action == NSSelectorFromString(@"copy:");
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    if (action == @selector(copy:)) {
        UIImage *image = [self.sourceImages objectAtIndex:indexPath.item];
        [UIPasteboard generalPasteboard].image = image;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIImage *image = [self.sourceImages objectAtIndex:indexPath.item];
    [self openImageFullScreen:image];
}

#pragma mark - Open Image

- (void) openImageFullScreen: (UIImage*) image {
    
    UIStoryboard *defaultStorybord = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [defaultStorybord instantiateViewControllerWithIdentifier:@"FullScreenVC"];
    FullScreenVC *imageFullScreen = nav.viewControllers.firstObject;
    imageFullScreen.image = image;
    imageFullScreen.name = self.searchName;

    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Search Action

- (IBAction)showSearchView:(UIBarButtonItem *)sender {
    UIAlertController *searchAlert = [UIAlertController alertControllerWithTitle:@"Search Images" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [searchAlert addTextFieldWithConfigurationHandler:nil];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
        
        NSString *text = searchAlert.textFields.firstObject.text;
        [self searchImage:text];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [searchAlert addAction:ok];
    [searchAlert addAction:cancel];
    
    [self presentViewController:searchAlert animated:YES completion:nil];
}

- (void) searchImage: (NSString*)searchString {
    
    [self setupTitle:searchString];
    self.searchName = searchString;
    
    [self clearCollectionView];
    
    //start load spinner
    [self.spinner startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.googleImage searchImages:searchString];
}

- (IBAction)showDogBreeds:(UIBarButtonItem *)sender {
    PickBreedsTableVC *pickTVC = [[PickBreedsTableVC alloc] init];
    pickTVC = [[PickBreedsTableVC alloc] init];
    pickTVC.listOfBreeds = self.googleImage.dogBreeds;
    pickTVC.typeOfBreed = Dog;
    pickTVC.delegate = self;
    pickTVC.title = @"Pick a dog breed";
    self.pickTVC = pickTVC;
    
    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:pickTVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)showCatsBreeds:(UIBarButtonItem *)sender {
    PickBreedsTableVC *pickTVC = [[PickBreedsTableVC alloc] init];
    pickTVC = [[PickBreedsTableVC alloc] init];
    pickTVC.listOfBreeds = self.googleImage.catBreeds;
    pickTVC.typeOfBreed = Cat;
    pickTVC.delegate = self;
    pickTVC.title = @"Pick a cat breed";
    self.pickTVC = pickTVC;
    
    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:pickTVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void) clearCollectionView {
    
    self.navigationController.hidesBarsOnSwipe = NO;
    
    for (NSURLSessionDataTask *dataTask in self.downloadTasks) {
        [dataTask cancel];
    }
    self.downloadTasks = [NSMutableArray array];
    _countOfDataTask = 0;
    
    self.sourceImages = [NSMutableArray array];
    self.showImages = [NSMutableArray array];
    
    [self.collectionViewSizeCalculator clearCache];
    [self.collectionView reloadData];
}

#pragma mark - SearchImagesDelegate

- (void) foundImages:(NSArray<NSString *> *)images {
    [self generateAllImage: images];
}

- (void) parseReady:(NSArray<NSString *> *)breeds
             typeOf:(TypeOfBreed)typeOfBreed {
    
    if (self.pickTVC.typeOfBreed == typeOfBreed) {
        self.pickTVC.listOfBreeds = breeds;
    }
}

@end
