//
//  ViewController.m
//  libAPTObjc
//
//  Created by Brian Olencki on 11/20/16.
//  Copyright © 2016 Brian Olencki. All rights reserved.
//

#import "ViewController.h"

#import "APTOManager.h"
#import "APTOPackageManager.h"
#import "APTOPackage.h"
#import "APTOSourceManager.h"
#import "APTOSource.h"

@interface ViewController () {
    NSArray *aryItem;
    
    APTOManager *manager;
    APTOSourceManager *sourceManager;
    APTOPackageManager *packageManager;
}
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"- viewDidLoad\nAttempting to load packages");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
    
    manager = [APTOManager sharedManager];
    sourceManager = [[APTOSourceManager alloc] initWithManager:manager];
    
    [sourceManager addSource:@"http://repo.bolencki13.com/" toListLocation:[manager.sourceFile stringByAppendingString:@"/sources.list"]];
    [sourceManager updateSources];
    
//    aryItem = [sourceManager sources]; /* Uncomment if you want to display sources */
    
    packageManager = [[APTOPackageManager alloc] initWithManager:manager withSourceManager:sourceManager];
    [packageManager updatePackages];

    aryItem = [[packageManager packages] allObjects]; /* Uncommend if you want to display packages */
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (void)addSource:(UIBarButtonItem*)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"libAPTObjc" message:@"Add Source" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Source URL";
        textField.text = @"https://";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add Source" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [sourceManager addSource:alert.textFields[0].text toListLocation:[manager.sourceFile stringByAppendingString:@"/sources.list"]];
        [sourceManager updateSources];
        [packageManager updatePackages];
        aryItem = [[packageManager packages] allObjects];
        [self.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Other
- (void)dependanciesForPackage:(APTOPackage*)package {
    NSError *error = nil;
    NSArray *aryDependancies = [packageManager dependanciesForPackage:package error:&error];
    
    if (error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"libAPTObjc" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    NSMutableArray *aryPackages = [NSMutableArray new];
    for (APTOPackage *dependancy in aryDependancies) {
        [aryPackages addObject:dependancy.pkgPackage];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"libAPTObjc" message:[NSString stringWithFormat:@"%@",aryPackages] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)conflictsForPackage:(APTOPackage*)package {
    NSError *error = nil;
    NSArray *aryConflicts = [packageManager conflictsForPackage:package error:&error];
    
    if (error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"libAPTObjc" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    NSMutableArray *aryPackages = [NSMutableArray new];
    for (APTOPackage *conflict in aryConflicts) {
        [aryPackages addObject:conflict.pkgPackage];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"libAPTObjc" message:[NSString stringWithFormat:@"%@",aryPackages] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)downloadURLForPackage:(APTOPackage*)package {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"libAPTObjc" message:package.downloadURL preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [aryItem count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"com.bolencki13.libAPTObjc.cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    id object = [aryItem objectAtIndex:indexPath.row];
    if ([object isKindOfClass:[APTOSource class]]) {
        cell.textLabel.text = ((APTOSource*)object).srcLabel;
        cell.detailTextLabel.text = ((APTOSource*)object).srcUrl;
    } else if ([object isKindOfClass:[APTOPackage class]]) {
        cell.textLabel.text = ((APTOPackage*)object).pkgName;
        cell.detailTextLabel.text = ((APTOPackage*)object).pkgPackage;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    APTOPackage *package = [packageManager packageWithBundleIdentifier:[tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Action" message:@"Choose action:" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Show Dependancies" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dependanciesForPackage:package];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Show Conflicts" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self conflictsForPackage:package];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Download URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self downloadURLForPackage:package];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
