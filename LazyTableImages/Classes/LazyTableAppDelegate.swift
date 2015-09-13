//
//  LazyTableAppDelegate.swift
//  LazyTableImages
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/03.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Application delegate for the LazyTableImages sample.
  It also downloads in the background the "Top Paid iPhone Apps" RSS feed using NSURLSession/NSURLSessionDataTask.
 */

import UIKit

@UIApplicationMain
@objc(LazyTableAppDelegate)
class LazyTableAppDelegate : UIResponder, UIApplicationDelegate, NSURLConnectionDataDelegate {
    
    var window: UIWindow?
    
    
    // the http URL used for fetching the top iOS paid apps on the App Store
    final let TopPaidAppsFeed =
    "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml"
    
    
    // the queue to run our "ParseOperation"
    private var queue: NSOperationQueue?
    
    // the NSOperation driving the parsing of the RSS feed
    private var parser: ParseOperation!
    
    
    //MARK: -
    
    // -------------------------------------------------------------------------------
    //	application:didFinishLaunchingWithOptions:
    // -------------------------------------------------------------------------------
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        let request = NSURLRequest(URL: NSURL(string: TopPaidAppsFeed)!)
        
        // create an session data task to obtain and the XML feed
        let sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            // in case we want to know the response status code
            //let HTTPStatusCode = (response as! NSHTTPURLResponse).statusCode
            
            if let actualError = error {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    var isATSError: Bool = false
                    if #available(iOS 9.0, *) {
                        isATSError = actualError.code == NSURLErrorAppTransportSecurityRequiresSecureConnection
                    }
                    if isATSError {
                        // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        //
                        abort()
                    } else {
                        self.handleError(actualError)
                    }
                }
            } else {
                // create the queue to run our ParseOperation
                self.queue = NSOperationQueue()
                
                // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
                self.parser = ParseOperation(data: data!)
                
                self.parser.errorHandler = {[weak self] parseError in
                    dispatch_async(dispatch_get_main_queue()) {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        self?.handleError(parseError)
                    }
                }
                
                // referencing parser from within its completionBlock would create a retain cycle
                
                self.parser.completionBlock = {[weak self] in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let recordList = self?.parser.appRecordList {
                        // The completion block may execute on any thread.  Because operations
                        // involving the UI are about to be performed, make sure they execute on the main thread.
                        //
                        dispatch_async(dispatch_get_main_queue()) {
                            // The root rootViewController is the only child of the navigation
                            // controller, which is the window's rootViewController.
                            //
                            let rootViewController =
                            (self?.window!.rootViewController as! UINavigationController?)?.topViewController as! RootViewController?
                            
                            rootViewController?.entries = recordList
                            
                            // tell our table view to reload its data, now that parsing has completed
                            rootViewController?.tableView.reloadData()
                        }
                    }
                    
                    // we are finished with the queue and our ParseOperation
                    self?.queue = nil
                }
                
                self.queue?.addOperation(self.parser)
            }
        }
        
        sessionTask.resume()
        
        // show in the status bar that network activity is starting
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        return true
    }
    
    // -------------------------------------------------------------------------------
    //	handleError:error
    //  Reports any error with an alert which was received from connection or loading failures.
    // -------------------------------------------------------------------------------
    func handleError(error: NSError) {
        let errorMessage = error.localizedDescription
        
        // alert user that our current record was deleted, and then we leave this view controller
        //
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: "Cannot Show Top Paid Apps",
                message: errorMessage,
                preferredStyle: .ActionSheet)
            let OKAction = UIAlertAction(title: "OK", style: .Default) {action in
                // dissmissal of alert completed
            }
            
            alert.addAction(OKAction)
            
            self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(title: "Cannot Show Top Paid Apps",
                message: errorMessage,
                delegate: nil,
                cancelButtonTitle: "OK")
            
            alertView.show()
        }
    }
    
    
}