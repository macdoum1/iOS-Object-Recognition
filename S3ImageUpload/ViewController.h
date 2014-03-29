//
//  ViewController.h
//  S3ImageUpload
//
//  Created by Michael MacDougall on 9/15/13.
//  Copyright (c) 2013 Michael MacDougall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>
#import <AWSSQS/AWSSQS.h>
#import <AWSRuntime/AWSRuntime.h>
#import "AWSConstants.h"

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AmazonServiceRequestDelegate,UIPopoverControllerDelegate>

// Amazon Client Objects
@property (nonatomic, retain) AmazonS3Client *s3;
@property (nonatomic, retain) AmazonSQSClient *sqs;

// IBOutlets for On-screen elemenets
@property (nonatomic, retain) IBOutlet UIImageView *selectedImageView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *recognizeButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentControl;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *libraryBarButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cameraBarButton;

// UIImagePicker Object
@property (nonatomic, retain) UIImagePickerController *imagePicker;

// Popover for UIImagePicker on iPad
@property (nonatomic, strong) UIPopoverController *popover;

// Timer used for background message checking
@property (nonatomic, retain) NSTimer *timer;

// Unique ID used for sending/recieving messages (Determining which results, are for which device)
@property (nonatomic, retain) NSString *uniqueId;

// IBActions for Interface Actions
- (IBAction)photoFromLibrary:(id)sender;
- (IBAction)photoFromCamera:(id)sender;
- (IBAction)uploadToS3:(id)sender;
- (IBAction)segmentChanged:(id)sender;

@end
