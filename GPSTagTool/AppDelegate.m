//
//  AppDelegate.m
//  GPSTagTool
//
//  Created by Zakk Hoyt on 9/27/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "AppDelegate.h"
#import "FileController.h"
static NSString *VWWGPSToolOutputURLKey = @"outputURL";
@interface AppDelegate ()

@property (weak) IBOutlet NSButton *findButton;
@property (weak) IBOutlet NSButton *findThenCopyButton;
@property (weak) IBOutlet NSPathControl *findPathControl;
@property (weak) IBOutlet NSPathControl *findThenCopyPathControl;
@property (weak) IBOutlet NSButton *recursiveCheckButton;
@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;
@property (weak) IBOutlet NSTextField *findCountLabel;
@property (weak) IBOutlet NSButton *linkCheckButton;

@property (weak) IBOutlet NSTextField *findAndCopyCountLabel;
@property (weak) IBOutlet NSButton *preserveDirStructureButton;

@property (weak) IBOutlet NSWindow *window;
@property (strong) FileController *fileController;
@property (weak) IBOutlet NSTextField *fileTypesTextField;
@property (nonatomic, strong) NSMutableString *outputString;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    self.fileController = [[FileController alloc]init];
    
    
    // set find path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
    NSString *picturesPath = [paths objectAtIndex:0];
    NSURL *picturesURL = [NSURL fileURLWithPath:picturesPath];
    [self.findPathControl setURL:picturesURL];
    
    // Set copy path
    NSString *outputURLString = [[NSUserDefaults standardUserDefaults] objectForKey:VWWGPSToolOutputURLKey];
    NSURL *outputURL = nil;
    if(outputURLString == nil){

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
        NSString *picturesPath = [paths objectAtIndex:0];
        NSURL *picturesURL = [NSURL fileURLWithPath:picturesPath];
        picturesURL = [picturesURL URLByDeletingLastPathComponent];
        outputURL = [picturesURL URLByAppendingPathComponent:@"GPSTagTool"];
        [[NSUserDefaults standardUserDefaults] setObject:outputURL.path forKey:VWWGPSToolOutputURLKey];
    }
    outputURL = [NSURL fileURLWithPath:outputURLString];
    [self.findThenCopyPathControl setURL:outputURL];

    self.findCountLabel.stringValue = @"";
    self.findAndCopyCountLabel.stringValue = @"";
    
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#pragma mark Private methods
-(void)enableControls:(BOOL)enabled{
    if(enabled){
        self.findButton.enabled = YES;
        self.findThenCopyButton.enabled = YES;
        self.findPathControl.enabled = YES;
        self.findThenCopyPathControl.enabled = YES;
        self.fileTypesTextField.enabled = YES;
        self.recursiveCheckButton.enabled = YES;
        self.preserveDirStructureButton.enabled = YES;
        
        self.findButton.alphaValue = 1.0;
        self.findThenCopyButton.alphaValue = 1.0;
        self.findPathControl.alphaValue = 1.0;
        self.findThenCopyPathControl.alphaValue = 1.0;
        self.fileTypesTextField.alphaValue = 1.0;
        self.recursiveCheckButton.alphaValue = 1.0;
        self.preserveDirStructureButton.alphaValue = 1.0;

    } else {
        self.findButton.enabled = NO;
        self.findThenCopyButton.enabled = NO;
        self.findPathControl.enabled = NO;
        self.findThenCopyPathControl.enabled = NO;
        self.fileTypesTextField.enabled = NO;
        self.recursiveCheckButton.enabled = NO;
        self.preserveDirStructureButton.enabled = NO;

        CGFloat alpha = 0.7;
        self.findButton.alphaValue = alpha;
        self.findThenCopyButton.alphaValue = alpha;
        self.findPathControl.alphaValue = alpha;
        self.findThenCopyPathControl.alphaValue = alpha;
        self.fileTypesTextField.alphaValue = alpha;
        self.recursiveCheckButton.alphaValue = alpha;
        self.preserveDirStructureButton.alphaValue = alpha;

    }
}


-(void)setupImageTypes{
    NSString *allowedTypes = self.fileTypesTextField.stringValue;
    NSArray *types = [allowedTypes componentsSeparatedByString:@"|"];
    NSMutableArray *cleanTypes = [[NSMutableArray alloc]initWithCapacity:types.count];
    for(NSString *type in types){
        NSString *cleanType = [type stringByReplacingOccurrencesOfString:@" " withString:@""];
        [cleanTypes addObject:cleanType.lowercaseString];
    }
    self.fileController.imageTypes =  [NSSet setWithArray:cleanTypes];
}

#pragma mark IBActions
- (IBAction)findButtonAction:(id)sender {
    [self enableControls:NO];
    [self setupImageTypes];
    self.outputTextView.string = @"";
    self.outputString = [[NSMutableString alloc]initWithString:@""];
    self.findCountLabel.stringValue = @"";
    __block NSUInteger counter = 0;
    BOOL recursive = (BOOL)self.recursiveCheckButton.state == NSOnState;
    [self.fileController findFilesWithGPSTagAtURL:self.findPathControl.URL recursive:recursive copy:NO updateBlock:^(NSURL *url) {
        [self.outputString setString:[NSString stringWithFormat:@"\"%@\"\n%@", url.path, self.outputString]];
        self.outputTextView.string = self.outputString;
        counter++;
        self.findCountLabel.stringValue = [NSString stringWithFormat:@"Found: %ld", (long)counter];
    } completionBlock:^(NSURL *url) {
        [self enableControls:YES];
    }];
    
    
}

- (IBAction)findThenCopyButtonAction:(id)sender {
    
    [self enableControls:NO];
    [self setupImageTypes];
    
    self.outputTextView.string = @"";
    self.outputString = [[NSMutableString alloc]initWithString:@""];
    BOOL recursive = (BOOL)self.recursiveCheckButton.state == NSOnState;
    self.findAndCopyCountLabel.stringValue = @"";
    BOOL preserveDirStructure = self.preserveDirStructureButton.state == NSOnState;
    self.fileController.preserveDirectoryStructure = preserveDirStructure;
    BOOL link = self.linkCheckButton.state == NSOnState;
    self.fileController.link = link;
    __block NSUInteger counter = 0;
    self.fileController.outputURL = self.findThenCopyPathControl.URL;
    [self.fileController findFilesWithGPSTagAtURL:self.findPathControl.URL recursive:recursive copy:YES updateBlock:^(NSURL *url) {
        [self.outputString setString:[NSString stringWithFormat:@"\"%@\"\n%@", url.path, self.outputString]];
        self.outputTextView.string = self.outputString;
        counter++;
        self.findAndCopyCountLabel.stringValue = [NSString stringWithFormat:@"Found and copied: %ld", (long)counter];
    } completionBlock:^(NSURL *url) {
        [self enableControls:YES];
    }];
    


}



@end
