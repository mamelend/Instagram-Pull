//
//  ViewController.m
//  InstagramPlus
//
//  Created by Miguel Melendez on 6/8/16.
//  Copyright © 2016 Miguel Melendez. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *likesLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logOutButton.enabled = false;
    self.refreshButton.enabled = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logInButtonPressed:(id)sender {
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Instagram"];
    self.logInButton.enabled = false;
    self.logOutButton.enabled = true;
    self.refreshButton.enabled = true;
}

- (IBAction)logOutButtonPressed:(id)sender {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    for (id acct in instagramAccounts)
        [store removeAccount:acct];
    self.logInButton.enabled = true;
    self.logOutButton.enabled = false;
    self.refreshButton.enabled = false;
}

- (IBAction)refreshButtonPressed:(id)sender {
    NSArray *instagramAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"Instagram"];
    if ([instagramAccounts count] == 0) {
        NSLog(@"Warning: %ld Instagram accounts logged in", (long)[instagramAccounts count]);
        return;
    }
    NXOAuth2Account *acct = instagramAccounts[0];
    NSString *token = acct.accessToken.accessToken;
    NSString *urlStr = [@"https://api.instagram.com/v1/users/self/media/recent/?access_token=" stringByAppendingString:token];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        // Check for network error
        if (error) {
            NSLog(@"Error: Couldn't finsih request: %@", error);
            return;
        }
        
        // Check for http error
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
            NSLog(@"Error: Got status code: %ld", (long)httpResp.statusCode);
            return;
        }
        
        // Check for JSON parse error
        NSError *parseErr;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
        
        if (!pkg) {
            NSLog(@"Error: Couldn't parse response: %@", parseErr);
            return;
        }
        
        NSString *imageURLStr = pkg[@"data"][0][@"images"][@"standard_resolution"][@"url"];
        NSString *likes = pkg[@"data"][0][@"likes"][@"count"];
        
        NSURL *imageURL = [NSURL URLWithString:imageURLStr];
        
        [[session dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            // Check for network error
            if (error) {
                NSLog(@"Error: Couldn't finsih request: %@", error);
                return;
            }
            
            // Check for http error
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
                NSLog(@"Error: Got status code: %ld", (long)httpResp.statusCode);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [UIImage imageWithData:data];
                self.likesLabel.text = [NSString stringWithFormat:@"%@ likes!", likes];
            });
            
        } ]resume];

        
    } ]resume];
}

@end
