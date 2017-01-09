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
    
    private var sessionTask: URLSessionDataTask?
    
    
    //MARK: -
    
    // -------------------------------------------------------------------------------
    //	startDownload
    // -------------------------------------------------------------------------------
    func startDownload() {
        let request = URLRequest(url: URL(string: self.appRecord!.imageURLString!)!)
        
        // create an session data task to obtain and download the app icon
        sessionTask = URLSession.shared.dataTask(with: request, completionHandler: {
            data, response, error in
            
            // in case we want to know the response status code
            //let httpStatusCode = (response as! HTTPURLResponse).statusCode
            
            if let actualError = error as NSError? {
                if #available(iOS 9.0, *) {
                    if actualError.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                        // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        //
                        abort()
                    }
                }
            }
            
            OperationQueue.main.addOperation{
                
                // Set appIcon and clear temporary data/image
                let image = UIImage(data: data!)!
                
                if image.size.width != kAppIconSize || image.size.height != kAppIconSize {
                    let itemSize = CGSize(width: kAppIconSize, height: kAppIconSize)
                    UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
                    let imageRect = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height)
                    image.draw(in: imageRect)
                    self.appRecord!.appIcon = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                } else {
                    self.appRecord!.appIcon = image
                }
                
                // call our completion handler to tell our client that our icon is ready for display
                self.completionHandler?()
            }
        }) 
        
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
