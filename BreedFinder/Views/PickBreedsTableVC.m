//
//  PickBreedsTableVCTableViewController.m
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "PickBreedsTableVC.h"



NSString* const cellIdentifier = @"pick_breed";

@interface PickBreedsTableVC () <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (strong, nonatomic) NSArray <NSString*> *searchResult;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation PickBreedsTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    self.navigationController.delegate = self;
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self.clearsSelectionOnViewWillAppear = NO;
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.searchResult = self.listOfBreeds;
    
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

- (void) setListOfBreeds:(NSArray<NSString *> *)listOfBreeds {
    _listOfBreeds = listOfBreeds;
    if (_listOfBreeds) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            self.searchResult = listOfBreeds;
            [self.tableView reloadData];
        });
    }
}

#pragma mark - Search Action

- (void) filterContentForSearch:(NSString*)searchText {
    
    if (!searchText || [searchText isEqualToString:@""]) {
        self.searchResult = self.listOfBreeds;
        [self.tableView reloadData];
        return;
    }
    
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
    self.searchResult = [self.listOfBreeds filteredArrayUsingPredicate:searchPredicate];
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
     [self filterContentForSearch:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}



#pragma mark - Landscape mode

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if (self.view.frame.size.width != size.width) {
        self.spinner.center = CGPointMake(size.width / 2, size.height / 2);
    }
    [self.searchBar resignFirstResponder];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    return [self supportedInterfaceOrientations];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Action

- (void) cancelAction: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResult count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    NSString *breed = [self.searchResult objectAtIndex:indexPath.item];
    cell.textLabel.text = breed;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *breed = [self.searchResult objectAtIndex:indexPath.item];
    [self.delegate searchImage:breed];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
    [self.searchBar setShowsCancelButton:NO animated:YES];
}

@end

