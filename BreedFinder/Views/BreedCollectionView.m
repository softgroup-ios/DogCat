//
//  BreedCollectionView.m
//  BreedFinder
//
//  Created by sxsasha on 21.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "BreedCollectionView.h"
#import "GoogleImages.h"
#import "ImageObject.h"
#import "BreedCell.h"

@interface BreedCollectionView () <UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic,strong) NSArray* arrayOfImages;
@property (nonatomic,strong) NSArray* arrayOfImageObject;
@property (nonatomic,strong) GoogleImages* googleImage;
@property (nonatomic,strong) UIPickerView* pickerView;
@property (nonatomic,assign) BOOL stop;
@property (nonatomic,assign) NSInteger  whatPick;

@property (nonatomic,assign) dispatch_queue_t queue11;

@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout *flowLayout;

@end


@implementation BreedCollectionView

static NSString * const reuseIdentifier = @"BreedImage";


- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.stop = NO;
    self.googleImage = [[GoogleImages alloc]init];
    
    // Uncomment the following line to preserve selection between presentations
     self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[BreedCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.itemSize = CGSizeMake(100, 100);
    flowLayout.headerReferenceSize = CGSizeZero;
    flowLayout.footerReferenceSize = CGSizeZero;
    flowLayout.sectionInset = UIEdgeInsetsZero;

    [self.collectionView setCollectionViewLayout:flowLayout];
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   // [self.collectionView registerClass:[BreedCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.arrayOfImageObject count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BreedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    ImageObject* imageObject = [self.arrayOfImageObject objectAtIndex:indexPath.row];
    cell.imageView.image = imageObject.image;
    
    return cell;
}

///

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100, 100);
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 1;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

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
    self.whatPick = whichBreedCheck;
    NSString* string = [self.googleImage.arrayOfBreeds objectAtIndex:whichBreedCheck];
    
    self.stop = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.arrayOfImages = nil;
        self.arrayOfImageObject = nil;
        [self.collectionView reloadData];
        self.stop = NO;
        [self.googleImage searchImages:string afterBlock:^(NSArray *arrayOfImages) {
            self.arrayOfImages = arrayOfImages;
            self.arrayOfImageObject = [self generateAllImage];
        }];
    });
}

#pragma mark - Help Method

-(NSArray*) generateAllImage
{
    __block NSMutableArray* array = [NSMutableArray array];
    
    dispatch_queue_t queue = dispatch_queue_create("downloadAndCreateItem", DISPATCH_QUEUE_CONCURRENT);
    
    for (NSString* imageString in self.arrayOfImages)
    {
    //NSString *imageString = self.arrayOfImages.firstObject;
        if (self.stop)
        {break;}
        dispatch_async(queue, ^{
            ImageObject* imageObject = [[ImageObject alloc]initWithImageURL:imageString andNumberOfbreed:self.whatPick];
            if (self.stop)
            {
                // NSLog(@"1dsdf: STOP");
                imageObject = nil;
                return;
            }
            if (imageObject.numberOfBreed!=self.whatPick)
            {
                // NSLog(@"2dsdf: %lu",(unsigned long)imageObject.numberOfBreed);
                imageObject = nil;
                return;
            }
            if (imageObject)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [array addObject:imageObject];
#warning need finish work
                    [self.collectionView reloadData];
                    // update collectionView
                   // [self.collectionView beginUpdates];
                    //NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.arrayOfImageObject count] - 1   inSection:0];
                    //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    //[self.tableView endUpdates];
                });
            }
        });
    }
    
    return array;
}

#pragma mark - UIPickerViewDataSource

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
