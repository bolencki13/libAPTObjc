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
}
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    APTOManager *manager = [APTOManager sharedManager];
    APTOSourceManager *sourceManager = [[APTOSourceManager alloc] initWithManager:manager];
    
    [sourceManager addSource:@"http://repo.bolencki13.com/" toListLocation:[manager.sourceFile stringByAppendingString:@"/sources.list"]];
    [sourceManager updateSources];
    
//    aryItem = [sourceManager sources]; /* Uncomment if you want to display sources */
    
    APTOPackageManager *packageManager = [[APTOPackageManager alloc] initWithManager:manager withSourceManager:sourceManager];
    [packageManager updatePackages];

    aryItem = [[packageManager packages] allObjects]; /* Uncommend if you want to display packages */
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if ([object isKindOfClass:[APTOSource class]]) cell.textLabel.text = ((APTOSource*)object).srcLabel;
    else if ([object isKindOfClass:[APTOPackage class]]) cell.textLabel.text = ((APTOPackage*)object).pkgName;
    
    return cell;
}
@end
