//
//  FullScreenVC.m
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "FullScreenVC.h"

@interface FullScreenVC () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic)   IBOutlet UIImageView *imageView;

@end

@implementation FullScreenVC

- (instancetype)initWithImage: (UIImage*)image andBreedName: (NSString*)name {
    self = [super init];
    if (self) {
        self.image = image;
        self.name = name;
        
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.frame = self.view.frame;
        self.scrollView.userInteractionEnabled = YES;
        self.scrollView.minimumZoomScale = 1.0f;
        self.scrollView.maximumZoomScale = 3.0f;
        self.scrollView.scrollEnabled = NO;
        self.scrollView.delegate = self;
        self.scrollView.backgroundColor = [UIColor blackColor];
        
        self.scrollView.clipsToBounds = NO;
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.pagingEnabled = YES;
        
        self.imageView = [[UIImageView alloc] initWithImage:image];
        self.imageView.frame = self.scrollView.frame;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor blackColor];
        [self.scrollView addSubview:self.imageView];
        
        self.view = self.scrollView;
    }
    return self;
}

- (void) viewDidLoad {
    
    self.scrollView.minimumZoomScale = 1.0f;
    self.scrollView.maximumZoomScale = 3.0f;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor blackColor];
    
    self.imageView.image = self.image;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor blackColor];

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelFullImage:)];
    UIBarButtonItem* saveToGallery = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveToGallery:)];
    self.title = self.name;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveToGallery;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.hidesBarsOnTap = YES;
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown:)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipe];
}

#pragma mark - Landscape mode

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if (self.view.frame.size.width != size.width) {
        //self.scrollView.frame = CGRectMake(0, 0, size.width, size.height);
        self.imageView.frame = CGRectMake(0, 0, size.width, size.height);
        self.scrollView.zoomScale = 1.f;
    }
}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}// any offset changes

- (void)scrollViewDidZoom:(UIScrollView *)scrollView NS_AVAILABLE_IOS(3_2) {
    
}// any zoom scale changes

// called on start of dragging (may require some time and or distance to move)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}
// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0) {
    
}
// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    
}// called on finger up as we are moving

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}// called when scroll view grinds to a halt

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
}
// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view NS_AVAILABLE_IOS(3_2) {
    
}// called before the scroll view begins zooming its content

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    
    if (scale != 1.0) {
        scrollView.scrollEnabled = YES;
        
    }
    else {
        scrollView.scrollEnabled = NO;
    }
}// scale between minimum and maximum. called after any 'bounce' animations

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return  NO;
}// return a yes if you want to scroll to the top. if not defined, assumes YES

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    
}

#pragma mark - Actions

- (void) swipeDown: (UITapGestureRecognizer*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) cancelFullImage: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) saveToGallery: (UIBarButtonItem*)sender {
    UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:savedWithError:contextInfo:), nil);
}

- (void)image:(UIImage*)image savedWithError:(NSError*)error contextInfo:(void *)contextInfo {
    
    if (error || !image) {
        return;
    }
    
    //Info View
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 150.f, 100.f)];
    view.center = self.view.center;
    view.backgroundColor = [UIColor whiteColor];
    [view setAlpha:0.0f];
    view.layer.cornerRadius = 8.f;
    [self.view addSubview:view];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Saved";
    label.font = [UIFont systemFontOfSize:23.f];
    label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    [label sizeToFit];
    
    float xpos = (view.frame.size.width/2.0f) - (label.frame.size.width/2.0f);
    float ypos = (view.frame.size.height/2.0f) - (label.frame.size.height/2.0f);
    [label setFrame:CGRectMake(xpos, ypos, label.frame.size.width, label.frame.size.height)];
    [view addSubview:label];
    
    [UIView animateWithDuration:0.7f animations:^{
        [view setAlpha:0.85f];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            [view setAlpha:0.0f];
        }];
    }];
}

@end

