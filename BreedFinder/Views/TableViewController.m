//
//  TableViewController.m
//  SuperImageTableView
//
//  Created by admin on 12.10.16.
//  Copyright © 2016 admin. All rights reserved.
//

#import "TableViewController.h"
#import "GoogleImages.h"
#import "ImageObject.h"

@interface TableViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic,strong) NSArray* arrayOfImages;
@property (nonatomic,strong) NSArray* arrayOfImageObject;
@property (nonatomic,strong) GoogleImages* googleImage;
@property (nonatomic,strong) UIPickerView* pickerView;
@property (nonatomic,assign) BOOL stop;
@property (nonatomic,assign) NSInteger  whatPick;

@property (nonatomic,assign) dispatch_queue_t queue11;

@end

@implementation TableViewController


#pragma mark - UIViewController method

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.stop = NO;
    self.googleImage = [[GoogleImages alloc]init];
    //self.arrayOfItems = [self generateAllItems];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
   // self.arrayOfItems = [self generateAllItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

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
        [self.tableView reloadData];
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
                                [self.tableView beginUpdates];
                                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.arrayOfImageObject count] - 1   inSection:0];
                                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                [self.tableView endUpdates];
                            });
                        }
                    });
                }

    return array;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.arrayOfImageObject count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"image";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    ImageObject* imageObject = [self.arrayOfImageObject objectAtIndex:indexPath.row];
    cell.imageView.image = imageObject.image;
    imageObject = nil;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
    {
        return 200;
    }
    return  100;
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
