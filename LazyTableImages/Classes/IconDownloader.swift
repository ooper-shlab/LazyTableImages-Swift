//
//  IconDownloader.swift
//  LazyTableImages
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/03.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Helper object for managing the downloading of a particular app's icon.
  It uses NSURLSession/NSURLSessionDataTask to download the app's icon in the background if it does not
  yet exist and works in conjunction with the RootViewController to manage which apps need their icon.
 */

import UIKit


private let kAppIconSize : CGFloat = 48

class IconDownloader : NSObject, NSURLConnectionDataDelegate {
    
    var appRecord: AppRecord?
    var completionHandler: (() -> Void)?
    
    private var sessionTask: NSURLSessionDataTask?
    
    
    //MARK: -
    
    // -------------------------------------------------------------------------------
    //	startDownload
    // -------------------------------------------------------------------------------
    func startDownload() {
        let request = NSURLRequest(URL: NSURL(string: self.appRecord!.imageURLString!)!)
        
        // create an session data task to obtain and download the app icon
        sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            // in case we want to know the response status code
            //let HTTPStatusCode = (response as! NSHTTPURLResponse).statusCode
            
            if let actualError = error {
                if #available(iOS 9.0, *) {
                    if actualError.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                        // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        //
                        abort()
                    }
                }
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock{
                
                // Set appIcon and clear temporary data/image
                let image = UIImage(data: data!)!
                
                if image.size.width != kAppIconSize || image.size.height != kAppIconSize {
                    let itemSize = CGSizeMake(kAppIconSize, kAppIconSize)
                    UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
                    let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
                    image.drawInRect(imageRect)
                    self.appRecord!.appIcon = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                } else {
                    self.appRecord!.appIcon = image
                }
                
                // call our completion handler to tell our client that our icon is ready for display
                self.completionHandler?()
            }
        }
        
        self.sessionTask?.resume()
    }
    
    // -------------------------------------------------------------------------------
    //	cancelDownload
    // -------------------------------------------------------------------------------
    func cancelDownload() {
        self.sessionTask?.cancel()
        sessionTask = nil
    }
    
}