<?php
// Michael MacDougall
// checkAndRun

require 'aws.phar';

use Aws\S3\S3Client;
use Aws\Sqs\SqsClient;

// Set up S3 Client
$s3Client = S3Client::factory(array(
	'key'		=>		'AKIAICFRNKXHEGIWAYHQ',
	'secret'	=>		'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',
));

// Set up SQS Client
$sqsClient = SqsClient::factory(array(
	'key'		=>		'AKIAICFRNKXHEGIWAYHQ',
	'secret'	=>		'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',
	'region'	=>		'us-west-2',
));

// Constants for S3 and SQS
$queueUrl = 'https://sqs.us-west-2.amazonaws.com/759738783135/michaelmacdougalltestqueue';
$bucketName = 'michaelmacdougalltestbucket';

$receiptHandle = '';
$messageContent = '';

while(true)
{
	// Receive Messages
	$sqsResult = $sqsClient->receiveMessage(array(
    	'QueueUrl' => $queueUrl,
	));
	
	// Parse messages
	$array = $sqsResult->getPath('Messages');
	$secondArray = $array[0];							
	$messageContent = $secondArray['Body'];
	$receiptHandle = $secondArray['ReceiptHandle'];
	
	// Check if message exists on queue
	if($messageContent != "")
	{
		// Get filename from message
		$intentIdAndImageArray = explode("|",$messageContent);
		
		// Check if message is intended for server
		if($intentIdAndImageArray[0] == "S")
		{

			$filename = $intentIdAndImageArray[3];

			// Download image from S3
			$downloadPath = $filename;
			//echo $filename;
			$s3Result = $s3Client->getObject(array(
				'Bucket'	=> $bucketName,
				'Key'		=> $filename,
				'SaveAs'	=> $downloadPath
			));
	
			// Check if recognizing or not
			if($intentIdAndImageArray[1] == "R")
			{
				// Execute Object Recognition
				$executionStr = './ObjRec ' . $filename;
				$output = exec($executionStr);
			
				// Send Results to Queue
				$results = 'D|' . $intentIdAndImageArray[2] . '|R|' . $output;
				$sqsResult = $sqsClient->sendMessage(array(
					'QueueUrl'		=> $queueUrl,
					'MessageBody'	=> $results
				));
				
			}
			// Adding Object
			else
			{
				// Excute AddObj
				$executionStr = './AddObj ' . $filename;
				$output = exec($executionStr);
				
				// Send Results to Queue
				$results = 'D|' . $intentIdAndImageArray[2] .'|A|Success';
				$sqsResult = $sqsClient->sendMessage(array(
					'QueueUrl'		=> $queueUrl,
					'MessageBody'	=> $results
				));
			}
			echo $results . "\n";
			/*echo "---HERE---";
			echo $filename;
			// Delete from S3
			/*$s3Result = $s3Client->deleteObject(array(
				'Bucket'	=> $bucketName,
				'Key'		=> $filename
			));*/

			// Delete from SQS
			$sqsResult = $sqsClient->deleteMessage(array(
				'QueueUrl'		=> $queueUrl,
				'ReceiptHandle'	=> $receiptHandle
			));
		
			// Delete Local File
			unlink($downloadPath);
		}
	}
}


?>