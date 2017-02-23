//
//  PickBreedsTableVCTableViewController.m
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "PickBreedsTableVC.h"
#import "GoogleImages.h"



NSString* const cellIdentifier = @"pick_breed";

@interface PickBreedsTableVC ()
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation PickBreedsTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self.clearsSelectionOnViewWillAppear = NO;
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}
- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    
    if (!self.googleImage.isParse) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.tableView reloadData];
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinner.center = CGPointMake(self.tableView.bounds.size.width / 2, self.tableView.bounds.size.height / 2);
        [self.spinner startAnimating];
        [self.view addSubview:self.spinner];
        
        PickBreedsTableVC *weakSelf = self;
        self.googleImage.imagesReady = ^(NSArray *array) {
            [weakSelf.spinner removeFromSuperview];
            weakSelf.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            [weakSelf.tableView reloadData];
        };
    }
}

#pragma mark - Action

- (void) cancelAction: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GoogleImagesDelegate

- (void) arrayOfBreedsReady: (NSArray*)breeds {
    
}
- (void) imagesReady: (NSArray*)images {
    
}

#pragma mark - UITableViewDelegate UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.googleImage.arrayOfBreeds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSString *breed = [self.googleImage.arrayOfBreeds objectAtIndex:indexPath.item];
    cell.textLabel.text = breed;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *breed = [self.googleImage.arrayOfBreeds objectAtIndex:indexPath.item];
    [self.delegate pickBreed:breed];
}

@end

