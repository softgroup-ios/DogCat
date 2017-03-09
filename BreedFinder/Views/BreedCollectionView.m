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
#import "UIScrollView+EmptyDataSet.h"



typedef void (^SuccessDownloadPhoto)(NSURL* imageURL);

@interface ImageObject : NSObject
@property (strong, nonatomic) NSString *imageURL;
@property (assign, nonatomic) CGSize imageSize;
@property (strong, nonatomic) UIImage *resizedImage;
@end

@implementation ImageObject
@end




@interface BreedCollectionView () <UINavigationControllerDelegate ,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,NSURLSessionTaskDelegate, GreedoCollectionViewLayoutDataSource, SuccessPickBreedDelegate, SearchImagesDelegate,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (nonatomic,strong) NSMutableArray <NSValue*>* sourceSizes;
@property (nonatomic,strong) NSMutableArray <ImageObject*>* showImages;
@property (nonatomic,strong) NSMutableArray <NSURLSessionDownloadTask*>* downloadTasks;
@property (nonatomic,assign) int countOfDataTask;

@property (nonatomic,strong) NSString* searchName;
@property (nonatomic,strong) GoogleImages* googleImage;
@property (weak, nonatomic) PickBreedsTableVC *pickTVC;

@property (strong, nonatomic) GreedoCollectionViewLayout *collectionViewSizeCalculator;

@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (assign, nonatomic) BOOL hideStatusBar;
@property (assign, nonatomic) BOOL isShowAddMoreButton;
@property (assign, nonatomic) BOOL isAllowLoadImage;
@property (assign, nonatomic) BOOL isEndLoading;
@property (assign, nonatomic) int leastToShowAddMore;
@property (strong, nonatomic) NSURLSession *session;

@end


@implementation BreedCollectionView

static NSString * const reuseIdentifier = @"BreedImage";


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataAndCollectionView];
}

- (void)initDataAndCollectionView {
    self.googleImage = [[GoogleImages alloc]init];
    self.googleImage.delegate = self;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.navigationController.delegate = self;
    
    
    self.collectionViewSizeCalculator = [[GreedoCollectionViewLayout alloc] initWithCollectionView:self.collectionView];
    self.collectionViewSizeCalculator.dataSource = self;
    self.collectionViewSizeCalculator.rowMaximumHeight = CGRectGetHeight(self.collectionView.bounds) / 3;
    self.collectionViewSizeCalculator.fixedHeight = NO;
    
    [self setupEmptyDataSet];
    
    //work with collection layout
    [self setupFlowLayout];
    
    //download spinner
    [self setupSpinner];
    
    [self initSession];
    
    self.navigationController.hidesBarsOnSwipe = NO;
    [self.navigationController.barHideOnSwipeGestureRecognizer addTarget:self action:@selector(swipe:)];
    
    self.clearsSelectionOnViewWillAppear = YES;
}

- (void) setupEmptyDataSet {
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
}

- (void)setupTitle:(NSString*)text {
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, 40)];
    titleLabel.text = text;
    titleLabel.font = [UIFont fontWithName:@"Kailasa" size:18.f];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.numberOfLines = 1;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = titleLabel;
}

- (void)setupFlowLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.minimumLineSpacing = 5;
    flowLayout.minimumInteritemSpacing = 5;
    
    CGFloat windowWidth =  [UIApplication sharedApplication].windows.firstObject.frame.size.width;
    flowLayout.itemSize = CGSizeMake(windowWidth/4, windowWidth/4);
    flowLayout.headerReferenceSize = CGSizeZero;
    flowLayout.footerReferenceSize = CGSizeZero;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    [self.collectionView setCollectionViewLayout:flowLayout];
}

- (void) setupSpinner {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.collectionView.bounds.size.width / 2, self.collectionView.bounds.size.height / 2);
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
}

- (void)initSession {
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.HTTPMaximumConnectionsPerHost = 3;
    sessionConfig.timeoutIntervalForResource = 120;
    sessionConfig.timeoutIntervalForRequest = 120;
    self.session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
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
    
    _isAllowLoadImage = YES;
    for (NSString* imageString in imagesURLs) {
        [self downloadImage:imageString successBlock:^(NSURL *imageURL) {
            
            ImageObject *imageObject;
            NSIndexPath *indexPath;
            if (imageURL) {
                UIImage *sourceImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:imageURL.relativePath]];
                if (sourceImage) {
                    [self.sourceSizes addObject:[NSValue valueWithCGSize:sourceImage.size]];
                    
                    indexPath = [NSIndexPath indexPathForRow:self.sourceSizes.count-1 inSection:0];
                    CGSize imageSize = [self.collectionViewSizeCalculator sizeForPhotoAtIndexPath:indexPath];
                    imageObject = [[ImageObject alloc] init];
                    imageObject.resizedImage = [self imageWithImage:sourceImage scaledToSize:imageSize];
                    imageObject.imageURL = imageURL.relativePath;
                    imageObject.imageSize = sourceImage.size;
                }
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (_isAllowLoadImage) {
                    
                    _countOfDataTask--;
                    if (imageObject && indexPath) {
                        [self addNewCell:imageObject atIndexPath:indexPath];
                        
                        if (!_isEndLoading) {
                            [self.spinner stopAnimating];
                            [self.collectionView reloadEmptyDataSet];
                            self.navigationController.hidesBarsOnSwipe = YES;
                            _isEndLoading = YES;
                        }
                        
                        if (_countOfDataTask <= _leastToShowAddMore) {
                            [self showAddMoreButton];
                        }
                    }
                    else if ((_countOfDataTask <= _leastToShowAddMore) && !self.isShowAddMoreButton) {
                        [self showAddMoreButton];
                    }
                    
                    if (_countOfDataTask <= 0) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    }
                }
                else {
                    [self clearCollectionView];
                }
            });
        }];
        _countOfDataTask++;
    }
}

- (void)addNewCell:(ImageObject*)imageObject atIndexPath:(NSIndexPath*)indexPath {
    if (self.showImages.count == indexPath.row) {
        [self.collectionView performBatchUpdates:^{
            [self.showImages addObject:imageObject];
            [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
        } completion:nil];
    }
    else {
        [self clearCollectionView];
    }
}

- (void)downloadImage:(NSString*)urlString
         successBlock:(SuccessDownloadPhoto)successBlock {

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if ([error.localizedDescription isEqualToString:@"cancelled"]) {
            return;
        }
        
        if (!location || error) {
            successBlock(nil);
            return;
        }
        successBlock(location);
    }];
    
    [downloadTask resume];
    [self.downloadTasks addObject:downloadTask];
}

- (void) showAddMoreButton {
    if (_isShowAddMoreButton) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.showImages.count-2 inSection:0];
        [self.sourceSizes removeObjectAtIndex:indexPath.row];
        
        [self.collectionView performBatchUpdates:^{
            [self.showImages removeObjectAtIndex:indexPath.row];
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        }
        completion:nil];
    }
    
    ImageObject *addMoreButton = [[ImageObject alloc] init];
    addMoreButton.resizedImage = [UIImage imageNamed:@"add-more.png"];
    addMoreButton.imageURL = @"add-more";
    
    [self.sourceSizes addObject:[NSValue valueWithCGSize:addMoreButton.resizedImage.size]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.sourceSizes.count-1 inSection:0];
    [self addNewCell:addMoreButton atIndexPath:indexPath];
    _isShowAddMoreButton = YES;
}


- (void) removeAddMoreButton {
    if (_isShowAddMoreButton) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.showImages.count-1 inSection:0];
        [self.sourceSizes removeObjectAtIndex:indexPath.row];
        
        [self.collectionView performBatchUpdates:^{
            [self.showImages removeObjectAtIndex:indexPath.row];
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        }
        completion:nil];
        _isShowAddMoreButton = NO;
    }
}
#pragma mark - GreedoCollectionViewLayoutDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.collectionViewSizeCalculator sizeForPhotoAtIndexPath:indexPath];
}

- (CGSize)greedoCollectionViewLayout:(GreedoCollectionViewLayout *)layout originalImageSizeAtIndexPath:(NSIndexPath *)indexPath  {
    if (indexPath.item < self.sourceSizes.count) {
        NSValue *sizeValue = [self.sourceSizes objectAtIndex:indexPath.item];
        return sizeValue.CGSizeValue;
    }
    
    return CGSizeMake(0.1, 0.1);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.showImages count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BreedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.imageView.image = [self.showImages objectAtIndex:indexPath.row].resizedImage;
    
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

#pragma mark - Copy menu Action

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    return action == NSSelectorFromString(@"copy:");
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    if (action == @selector(copy:)) {
        ImageObject *imageObject = [self.showImages objectAtIndex:indexPath.item];
        UIImage *sourceImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:imageObject.imageURL]];
        [UIPasteboard generalPasteboard].image = sourceImage;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_isShowAddMoreButton && indexPath.row == self.showImages.count-1) {
        [self removeAddMoreButton];
        _leastToShowAddMore = _leastToShowAddMore + 10;
        [self.googleImage searchMore];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        return;
    }
    
    ImageObject *imageObject = [self.showImages objectAtIndex:indexPath.item];
    [self openImageFullScreen:imageObject];
}

#pragma mark - Open Image

- (void)openImageFullScreen:(ImageObject*)imageObject {
    
    UIStoryboard *defaultStorybord = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [defaultStorybord instantiateViewControllerWithIdentifier:@"FullScreenVC"];
    
    FullScreenVC *imageFullScreen = nav.viewControllers.firstObject;
    imageFullScreen.name = self.searchName;
    imageFullScreen.image = imageObject.resizedImage;
    [self presentViewController:nav animated:YES completion:nil];
    
    UIImage *sourceImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:imageObject.imageURL]];
    [imageFullScreen setFullSizeImage:sourceImage];
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
        [searchAlert.textFields.firstObject resignFirstResponder];
    }];
    
    [searchAlert addAction:ok];
    [searchAlert addAction:cancel];
    
    [self presentViewController:searchAlert animated:YES completion:nil];
}

- (void)searchImage:(NSString*)searchString {
    
    if (!searchString || [searchString isEqualToString:@""]) {
        return;
    }
    
    _isAllowLoadImage = NO;
    _isEndLoading = NO;
    [self setupTitle:searchString];
    self.searchName = searchString;
    
    [self clearCollectionView];
    
    //start load spinner
    [self.spinner startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.googleImage searchImages:searchString];
}

- (IBAction)showDogBreeds:(UIBarButtonItem *)sender {
    
    UIStoryboard *defaultStorybord = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PickBreedsTableVC *pickTVC = [defaultStorybord instantiateViewControllerWithIdentifier:@"PickBreedsTableVC"];
    
    pickTVC.listOfBreeds = self.googleImage.dogBreeds;
    pickTVC.typeOfBreed = Dog;
    pickTVC.delegate = self;
    self.pickTVC = pickTVC;
    
    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:pickTVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)showCatsBreeds:(UIBarButtonItem *)sender {
    
    UIStoryboard *defaultStorybord = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PickBreedsTableVC *pickTVC = [defaultStorybord instantiateViewControllerWithIdentifier:@"PickBreedsTableVC"];
    
    pickTVC.listOfBreeds = self.googleImage.catBreeds;
    pickTVC.typeOfBreed = Cat;
    pickTVC.delegate = self;
    self.pickTVC = pickTVC;
    
    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:pickTVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)clearCollectionView {
    
    self.navigationController.hidesBarsOnSwipe = NO;
    for (NSURLSessionDownloadTask *downloadTask in self.downloadTasks.reverseObjectEnumerator) {
        [downloadTask cancel];
    }
    self.downloadTasks = [NSMutableArray array];
    _countOfDataTask = 0;
    _leastToShowAddMore = 10;
    
    self.sourceSizes = [NSMutableArray array];
    self.showImages = [NSMutableArray array];
    
    [self.collectionViewSizeCalculator clearCache];
    [self.collectionView reloadData];
}

#pragma mark - SearchImagesDelegate

- (void)foundImages:(NSArray<NSString *> *)images {
    if (images && images.count > 0) {
        [self generateAllImage: images];
    }
    else {
        _leastToShowAddMore = -1;
    }
}

- (void)parseReady:(NSArray<NSString *> *)breeds
            typeOf:(TypeOfBreed)typeOfBreed {
    
    if (self.pickTVC.typeOfBreed == typeOfBreed) {
        self.pickTVC.listOfBreeds = breeds;
    }
}

#pragma mark - DZNEmptyDataSetSource and DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"Happy to see you";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.firstLineHeadIndent = 10;
    paragraph.paragraphSpacing = 10;
    paragraph.headIndent = 5;
    
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    
    NSString *textOne = @"You can search cat/dog breed images, just tap on one of left-top buttons.\n";
    NSString *textTwo = @"Or you can search images with you own search request, just tap on right-top button.";
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:textOne attributes:attributes];
    [string appendAttributedString:[[NSMutableAttributedString alloc] initWithString:textTwo attributes:attributes]];
    
    return string;
}

@end
