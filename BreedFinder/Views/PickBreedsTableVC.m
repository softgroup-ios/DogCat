//
//  PickBreedsTableVCTableViewController.m
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "PickBreedsTableVC.h"



NSString* const cellIdentifier = @"pick_breed";

@interface PickBreedsTableVC () <UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation PickBreedsTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.navigationController.delegate = self;
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self.clearsSelectionOnViewWillAppear = NO;
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    if (!self.listOfBreeds) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.tableView reloadData];
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinner.center = CGPointMake(self.tableView.bounds.size.width / 2, self.tableView.bounds.size.height / 2);
        self.spinner.hidesWhenStopped = YES;
        [self.view addSubview:self.spinner];
        
        [self.spinner startAnimating];
    }
}

#pragma mark - Landscape mode

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if (self.view.frame.size.width != size.width) {
        self.spinner.center = CGPointMake(size.width / 2, size.height / 2);
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

- (void) setListOfBreeds:(NSArray<NSString *> *)listOfBreeds {
    _listOfBreeds = listOfBreeds;
    [self.spinner stopAnimating];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView reloadData];
}

#pragma mark - Action

- (void) cancelAction: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listOfBreeds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSString *breed = [self.listOfBreeds objectAtIndex:indexPath.item];
    cell.textLabel.text = breed;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *breed = [self.listOfBreeds objectAtIndex:indexPath.item];
    [self.delegate searchImage:breed];
}

@end

