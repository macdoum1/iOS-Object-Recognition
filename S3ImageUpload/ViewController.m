//
//  ViewController.m
//  S3ImageUpload
//
//  Created by Michael MacDougall on 9/15/13.
//  Copyright (c) 2013 Michael MacDougall. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize s3 = _s3;
@synthesize sqs = _sqs;
@synthesize imagePicker,selectedImageView;
@synthesize uniqueId,timer,recognizeButton,segmentControl,libraryBarButton,popover,cameraBarButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get/Set Unique ID
    uniqueId = [self uniqID];
    
    // Initalize the S3 Client
    if(self.s3 == nil)
    {
        self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
        self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
    }
    
    // Initialize the SQS Client
    if(self.sqs == nil)
    {
        self.sqs = [[AmazonSQSClient alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
        self.sqs.endpoint = [AmazonEndpoints sqsEndpoint:US_WEST_2];
    }

    // Initialize Image Picker and set delegate
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    
    // Initialize timer
    timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(getMessagesInBackground) userInfo:nil repeats:YES];
}

- (void)getMessagesInBackground
{
    // Get Message
    SQSReceiveMessageRequest *rmr = [[SQSReceiveMessageRequest alloc]initWithQueueUrl:QUEUE_URL];
    rmr.maxNumberOfMessages = [NSNumber numberWithInt:1];
    rmr.visibilityTimeout = [NSNumber numberWithInt:1];
    SQSReceiveMessageResponse *response = [self.sqs receiveMessage:rmr];
    if([response.messages count] > 0)
    {
        SQSMessage *message = [response.messages objectAtIndex:0];
        
        // Parse Message
        NSString *messageBody = message.body;
        NSString *messageRH = message.receiptHandle;
        NSArray *messageArray = [messageBody componentsSeparatedByString:@"|"];
        
        if([messageArray count] > 0)
        {
            // Check if intended for device with intent & unique ID
            if([[messageArray objectAtIndex:0]  isEqual: @"D"] && [[messageArray objectAtIndex:1] isEqual:uniqueId])
            {
                // Delete message from queue
                SQSDeleteMessageRequest *dmr = [[SQSDeleteMessageRequest alloc] initWithQueueUrl:QUEUE_URL andReceiptHandle:messageRH];
                SQSDeleteMessageResponse *dmres = [self.sqs deleteMessage:dmr];
                if(dmres.error != nil)
                {
                    NSLog(@"Delete Message Error: %@",dmres.error);
                }
                if([[messageArray objectAtIndex:2] isEqual: @"R"])
                {
                    // Check if result is match
                    if([[messageArray objectAtIndex:3] isEqual:@"M"])
                    {
                        NSString *matchWithPercent = [NSString stringWithFormat:@"%@ Percent: %@%%",[messageArray objectAtIndex:4],[messageArray objectAtIndex:5]];
                        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Match Found" message: matchWithPercent delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Match" message:@"No Match Found" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                }
                else
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Object Added" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alert show];
                }
                
                
                
                // Invalidate timer that fires background call to this method
                [timer invalidate];
            }
        }
    }
}

// Returns unique ID either from UIDevice, or creates one and stores it in NSUserDefaults
-(NSString*)uniqID
{
    // Initalize ID
    NSString* unId = nil;
    
    // Gets ID from UIDevice if iOS 6 or greater
    if( [UIDevice instancesRespondToSelector:@selector(identifierForVendor)] )
    {
        unId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    // Creates a new ID and stores it to NSUserdefaults if iOS 5 or earlier
    else
    {
        unId = [[NSUserDefaults standardUserDefaults] objectForKey:@"identiferForVendor"];
        if( !unId )
        {
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            unId = ( NSString*)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
            CFRelease(uuid);
            [[NSUserDefaults standardUserDefaults] setObject:unId forKey:@"identifierForVendor"];
        }
    }
    
    // Return ID
    return unId;
}

//***Image Selection***
- (IBAction)photoFromLibrary:(id)sender
{
    // Setup popover for iPad
    popover = [[UIPopoverController alloc]initWithContentViewController:imagePicker];
    popover.delegate = self;
    
    // Set UIImagePicker source to Library
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    
    // Check if iPad
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // Present UIImagePicker in popover
        [popover presentPopoverFromBarButtonItem:libraryBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        // Present UIImagePicker
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}
- (IBAction)photoFromCamera:(id)sender
{
    
    // Setup popover for iPad
    popover = [[UIPopoverController alloc]initWithContentViewController:imagePicker];
    popover.delegate = self;
    
    // Set UIImagePicker source to Library
    [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    
    // Check if iPad
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // Present UIImagePicker in popover
        [popover presentPopoverFromBarButtonItem:cameraBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        // Present UIImagePicker
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}
//*********************

//***UISegmentControl Changed***
- (IBAction)segmentChanged:(id)sender
{
    if(((UISegmentedControl *)sender).selectedSegmentIndex == 0)
    {
        recognizeButton.title = @"Recognize";
    }
    else
    {
        recognizeButton.title = @"Add Object";
    }
        
}
//******************************

//***ImagePicker Delegate Method(s)***
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // When finished picking image initialize as UIImage
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Display the UIImage in the UIImageView
    selectedImageView.image = image;
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        [popover dismissPopoverAnimated:YES];
    }
    else
    {
        // Dismiss UIImagePicker
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
//**********************************

//***Upload to S3***
- (IBAction)uploadToS3:(id)sender
{
    // Checks for presence of an image
    if(selectedImageView.image != nil)
    {
        // Uploads image in background
        [self performSelectorInBackground:@selector(uploadInBackground) withObject:nil];
        
        // Disables recognize button to avoid multiple uploads
        recognizeButton.enabled = NO;
    }
}

- (void) uploadInBackground
{
    // Get Image Data
    NSData *imageData = UIImageJPEGRepresentation(selectedImageView.image, 1.0);

    // Append random number to filename of image
    int randNum = arc4random() % 1000000000;
    NSString *imageName = [NSString stringWithFormat:@"image%d.jpg",randNum];
    
    // Upload image
    S3PutObjectRequest *putObj = [[S3PutObjectRequest alloc] initWithKey:imageName inBucket:BUCKET_NAME];
    putObj.contentType = @"image/jpeg";
    putObj.data = imageData;
    S3PutObjectResponse *putObjResponse = [self.s3 putObject:putObj];
    if(putObjResponse.error != nil)
    {
        NSLog(@"Upload Error: %@", putObjResponse.error);
    }
    
    
    // Make message string
    NSString *idAndImageName;
    
    // Determine intent based on UISegmentControl
    if(segmentControl.selectedSegmentIndex == 0)
    {
        idAndImageName = [NSString stringWithFormat:@"S|R|%@|%@",uniqueId,imageName];
    }
    else
    {
        idAndImageName = [NSString stringWithFormat:@"S|A|%@|%@",uniqueId,imageName];
    }
    
    // Send message
    SQSSendMessageRequest *sendMessageReq = [[SQSSendMessageRequest alloc] initWithQueueUrl:QUEUE_URL andMessageBody:idAndImageName     ];
    SQSSendMessageResponse *sendMessageRes = [self.sqs sendMessage:sendMessageReq];
    if(sendMessageRes.error != nil)
    {
        NSLog(@"Send Message Error: %@", sendMessageRes.error);
    }
    
    [self performSelectorOnMainThread:@selector(showAlert:) withObject:putObjResponse.error waitUntilDone:NO];
    timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(getMessagesInBackground) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)showAlert:(NSString *)status
{
    UIAlertView *alert;
    
    // If status is nonempty present an upload error UIAlert
    if(status != nil)
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Upload Error" message:status delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    // Enable recognize button to allow for next upload
    recognizeButton.enabled = YES;
}
//******************

//***AWS Delegate Methods***
-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
