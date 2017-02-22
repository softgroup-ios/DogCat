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

typedef void (^SuccessDownloadPhoto)(UIImage* image);

@interface FullScreenVC : UIViewController
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString *name;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithImage: (UIImage*)image andBreedName: (NSString*)name;
@end

@implementation FullScreenVC
- (instancetype)initWithImage: (UIImage*)image andBreedName: (NSString*)name {
    self = [super init];
    if (self) {
        self.image = image;
        self.name = name;
        self.view = [[UIImageView alloc] initWithImage:image];
        self.view.contentMode = UIViewContentModeScaleAspectFit;
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelFullImage:)];
    UIBarButtonItem* saveToGallery = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveToGallery:)];
    self.title = self.name;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveToGallery;
}

- (void) cancelFullImage: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) saveToGallery: (UIBarButtonItem*) sender {
    UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
}
@end




@interface BreedCollectionView () <UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GreedoCollectionViewLayoutDataSource>

@property (nonatomic,strong) NSArray <NSString*>* imagesURLs;
@property (nonatomic,strong) NSMutableArray <UIImage*>* images;
@property (nonatomic,strong) GoogleImages* googleImage;
@property (nonatomic,strong) UIPickerView* pickerView;

@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout *flowLayout;

@property (strong, nonatomic) GreedoCollectionViewLayout *collectionViewSizeCalculator;

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
}

#pragma mark - Load All Image

-(void) generateAllImage
{
    for (NSString* imageString in self.imagesURLs)
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
    UIViewController* popout = [[UIViewController alloc]init];
    
    self.pickerView = [[UIPickerView alloc]init];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.backgroundColor = [UIColor whiteColor];
    popout.view = self.pickerView;
    
    UINavigationController* navPopuout = [[UINavigationController alloc]initWithRootViewController:popout];
    navPopuout.modalPresentationStyle = UIModalPresentationPopover;
    navPopuout.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    navPopuout.popoverPresentationController.barButtonItem = sender;
    
    UIBarButtonItem* barItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePicker:)];
    
    popout.navigationItem.rightBarButtonItem = barItem;
    
    [self presentViewController:navPopuout animated:YES completion:nil];
}

-(void) donePicker: (UIBarButtonItem*) barItem
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSInteger whichBreedCheck = [self.pickerView selectedRowInComponent:0];
    NSString* string = [self.googleImage.arrayOfBreeds objectAtIndex:whichBreedCheck];
    self.title = string;
    
    self.imagesURLs = nil;
    self.images = [NSMutableArray array];
    [self.collectionView reloadData];
    [self.collectionViewSizeCalculator clearCache];
    [self.googleImage searchImages:string afterBlock:^(NSArray *arrayOfImages) {
        self.imagesURLs = arrayOfImages;
        [self generateAllImage];
    }];
}

#pragma mark <UIPickerViewDataSource>

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.googleImage.arrayOfBreeds count];
}
- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.googleImage.arrayOfBreeds objectAtIndex:row];
}




@end
