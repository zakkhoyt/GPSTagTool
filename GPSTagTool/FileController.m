//
//  FileController.m
//  GPSTagTool
//
//  Created by Zakk Hoyt on 9/27/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "FileController.h"
@import  ImageIO;


@interface FileController ()
@property (nonatomic, strong) NSMutableArray *filesWithGPSTags;
@property (nonatomic, strong) NSMutableArray *filesWithoutGPSTags;
@end

@implementation FileController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.filesWithGPSTags = [@[]mutableCopy];
        self.filesWithoutGPSTags = [@[]mutableCopy];
    }
    return self;
}
-(BOOL)createOutputURL:(NSURL*)outputURL{
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = NO;
    //    NSMutableArray *contents = [[fileManager contentsOfDirectoryAtPath:path error:&error]mutableCopy];
    if([fileManager fileExistsAtPath:outputURL.path]){
        return YES;
    } else {
        success = [fileManager createDirectoryAtURL:outputURL withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if(success == NO || error){
        NSLog(@"Could not create output dir");
        return NO;
    }
    return YES;
}


-(void)findFilesWithGPSTagAtURL:(NSURL*)url recursive:(BOOL)recursive copy:(BOOL)copy updateBlock:(VWWURLBlock)updateBlock completionBlock:(VWWEmptyBlock)completionBlock{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.filesWithGPSTags removeAllObjects];
        [self.filesWithoutGPSTags removeAllObjects];
//        [self findFilesWithGPSTagAtPath:url.path recursive:recursive copy:copy updateBlock:updateBlock];
        [self findFilesWithGPSTagAtPath:url.path  recursive:recursive copy:copy updateBlock:updateBlock];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock();
        });
    });
    
}



-(void)copyFilesToOutputDir:(NSURL*)outputURL updateBlock:(VWWURLErrorBlock)updateBlock completionBlock:(VWWIntIntBlock)completionBlock{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if([self createOutputURL:outputURL] == NO){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(0, 1);
            });
        }
        
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = NO;
        NSUInteger errorCounter = 0;
        NSInteger successCount = 0;
        for(NSURL *url in self.filesWithGPSTags){
            NSURL *finalURL = [outputURL URLByAppendingPathComponent:url.lastPathComponent];
            success = [fileManager copyItemAtURL:url toURL:finalURL error:&error];
            if(success == NO){
                errorCounter++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    updateBlock(url, [NSError errorWithDomain:@"vww" code:-100 userInfo:nil]);
                });
            } else if(error){
                errorCounter++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    updateBlock(url, error);
                });
            } else {
                successCount++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    updateBlock(url, nil);
                });
            }
        }
        completionBlock(successCount, errorCounter);
    });
}

-(BOOL)copyFileAtURL:(NSURL*)url toOutputURL:(NSURL*)outputURL{
    NSError *error;
    NSURL *finalURL = [outputURL URLByAppendingPathComponent:url.lastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager copyItemAtURL:url toURL:finalURL error:&error];
    if(success == NO){
        return NO;
    } else if(error){
        return NO;
    } else {
        return YES;
    }
}




#pragma mark Private methods

-(void)findFilesWithGPSTagAtPath:(NSString*)path recursive:(BOOL)recursive copy:(BOOL)copy updateBlock:(VWWURLBlock)updateBlock{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *contents = [[fileManager contentsOfDirectoryAtPath:path error:&error]mutableCopy];
    
    
    for(NSInteger index = 0; index < contents.count; index++){
        
        NSString *contentDetailsPath = [NSString stringWithFormat:@"%@/%@", path, contents[index]];
        contentDetailsPath = [contentDetailsPath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
        
        NSDictionary *contentsAttributes = [fileManager attributesOfItemAtPath:contentDetailsPath error:&error];
        
        BOOL isDirectory = contentsAttributes[NSFileType] == NSFileTypeDirectory ? YES : NO;
        
        NSURL *url = [NSURL fileURLWithPath:contentDetailsPath isDirectory:isDirectory];
        
        if(isDirectory){
            if([url.path rangeOfString:@"iPhoto Library.photolibrary"].location == NSNotFound){
                // Recurse
                [self findFilesWithGPSTagAtPath:url.path recursive:recursive copy:copy updateBlock:updateBlock];
            }
        } else {
            BOOL shouldInspectMetadata = NO;
            shouldInspectMetadata = [self urlIsImageType:url];

            if(shouldInspectMetadata){
                NSDictionary *metadata = [self readMetadataFromURL:url];
                NSDictionary *gpsDictionary = metadata[(NSString*)kCGImagePropertyGPSDictionary];
                BOOL hasGPSTag = NO;
                if(gpsDictionary) {
                    NSNumber *latitude = gpsDictionary[(NSString*)kCGImagePropertyGPSLatitude];
                    NSNumber *longitude = gpsDictionary[(NSString*)kCGImagePropertyGPSLongitude];
                    if(latitude && longitude){
                        hasGPSTag = YES;
                    }
                }
                if(hasGPSTag){
                    NSLog(@"GPS image: %@", url.path);
                    [self.filesWithGPSTags insertObject:url atIndex:0];
                    if(copy){
                        [self copyFileAtURL:url toOutputURL:self.outputURL];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        updateBlock(url);
                    });
                } else {
                    NSLog(@"just image: %@", url.path);
                    [self.filesWithoutGPSTags insertObject:url atIndex:0];
                }
            } else {
                NSLog(@"Ignoring file %@:", url.path);
            }
        }
    }
}


-(BOOL)urlIsImageType:(NSURL*)url{
    NSString *extension = [url.path pathExtension];
    return [self.imageTypes containsObject:extension.lowercaseString];
}

-(NSDictionary*)readMetadataFromURL:(NSURL*)url{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (imageSource == NULL) {
        //        NSLog(@"Could not read metadata for %@", url.path);
        return nil;
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache,
                             nil];
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    NSDictionary *metadata = nil;
    if (imageProperties) {
        metadata = (__bridge NSDictionary *)(imageProperties);
        CFRelease(imageProperties);
    }
    CFRelease(imageSource);
    
    return metadata;
}



@end
