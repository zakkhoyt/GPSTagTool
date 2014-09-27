//
//  FileController.h
//  GPSTagTool
//
//  Created by Zakk Hoyt on 9/27/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^VWWURLErrorBlock)(NSURL *url, NSError *error);
typedef void (^VWWIntIntBlock)(NSInteger successCount, NSInteger errorCount);
typedef void (^VWWURLBlock)(NSURL *url);
typedef void (^VWWEmptyBlock)();
typedef void (^VWWBOOLBlock)(BOOL success);
@interface FileController : NSObject
@property (nonatomic, strong) NSURL *outputURL;
@property (strong) NSSet *imageTypes;
@property (nonatomic) BOOL preserveDirectoryStructure;
@property (nonatomic) BOOL link;
-(void)findFilesWithGPSTagAtURL:(NSURL*)url recursive:(BOOL)recursive copy:(BOOL)copy updateBlock:(VWWURLBlock)updateBlock completionBlock:(VWWEmptyBlock)completionBlock;
-(void)copyFilesToOutputDir:(NSURL*)outputURL updateBlock:(VWWURLErrorBlock)updateBlock completionBlock:(VWWIntIntBlock)completionBlock;
@end
