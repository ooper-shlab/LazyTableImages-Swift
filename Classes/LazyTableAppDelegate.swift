//
//  LazyTableAppDelegate.swift
//  LazyTableImages
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/03.
//
//
/*
     File: LazyTableAppDelegate.h
     File: LazyTableAppDelegate.m
 Abstract: Application delegate for the LazyTableImages sample.
 It also downloads in the background the "Top Paid iPhone Apps" RSS feed using NSURLConnection.

  Version: 1.5

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2014 Apple Inc. All Rights Reserved.

 */

import UIKit
import CFNetwork

@UIApplicationMain
@objc(LazyTableAppDelegate)
class LazyTableAppDelegate : UIResponder, UIApplicationDelegate, NSURLConnectionDataDelegate {
    
    var window: UIWindow?
    
    
    // This framework was imported so we could use the kCFURLErrorNotConnectedToInternet error code.
    
    // the http URL used for fetching the top iOS paid apps on the App Store
    final let TopPaidAppsFeed =
    "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml"
    
    
    // the queue to run our "ParseOperation"
    private var queue: NSOperationQueue?
    // RSS feed network connection to the App Store
    private var appListFeedConnection: NSURLConnection?
    private var appListData: NSMutableData?
    
    
    //MARK: -
    
    // -------------------------------------------------------------------------------
    //	application:didFinishLaunchingWithOptions:
    // -------------------------------------------------------------------------------
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        let urlRequest = NSURLRequest(URL: NSURL(string: TopPaidAppsFeed)!)
        appListFeedConnection = NSURLConnection(request: urlRequest, delegate: self)
        
        // Test the validity of the connection object. The most likely reason for the connection object
        // to be nil is a malformed URL, which is a programmatic error easily detected during development
        // If the URL is more dynamic, then you should implement a more flexible validation technique, and
        // be able to both recover from errors and communicate problems to the user in an unobtrusive manner.
        //
        assert(self.appListFeedConnection != nil, "Failure to create URL connection.")
        
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
        if objc_getClass("UIAlertController") != nil {
            let alert = UIAlertController(title: "Cannot Show Top Paid Apps",
                message: errorMessage,
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            
            self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(title: "Cannot Show Top Paid Apps",
                message: errorMessage,
                delegate: nil,
                cancelButtonTitle: "OK")
            
            alertView.show()
        }
    }
    
    
    // The following are delegate methods for NSURLConnection. Similar to callback functions, this is how
    // the connection object,  which is working in the background, can asynchronously communicate back to
    // its delegate on the thread from which it was started - in this case, the main thread.
    
    //MARK: - NSURLConnectionDelegate
    
    // -------------------------------------------------------------------------------
    //	connection:didReceiveResponse:response
    //  Called when enough data has been read to construct an NSURLResponse object.
    // -------------------------------------------------------------------------------
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.appListData = NSMutableData()    // start off with new data
    }
    
    // -------------------------------------------------------------------------------
    //	connection:didReceiveData:data
    //  Called with a single immutable NSData object to the delegate, representing the next
    //  portion of the data loaded from the connection.
    // -------------------------------------------------------------------------------
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.appListData?.appendData(data)
    }
    
    // -------------------------------------------------------------------------------
    //	connection:didFailWithError:error
    //  Will be called at most once, if an error occurs during a resource load.
    //  No other callbacks will be made after.
    // -------------------------------------------------------------------------------
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if error.code == Int(CFNetworkErrors.CFURLErrorNotConnectedToInternet.rawValue) {
            // if we can identify the error, we can present a more precise message to the user.
            let userInfo : [NSObject : AnyObject] = [NSLocalizedDescriptionKey : "No Connection Error"]
            let noConnectionError = NSError(domain: NSCocoaErrorDomain,
                code: Int(CFNetworkErrors.CFURLErrorNotConnectedToInternet.rawValue),
                userInfo: userInfo)
            self.handleError(noConnectionError)
        } else {
            // otherwise handle the error generically
            self.handleError(error)
        }
        
        self.appListFeedConnection = nil   // release our connection
    }
    
    // -------------------------------------------------------------------------------
    //	connectionDidFinishLoading:connection
    //  Called when all connection processing has completed successfully, before the delegate
    //  is released by the connection.
    // -------------------------------------------------------------------------------
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.appListFeedConnection = nil
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        // create the queue to run our ParseOperation
        self.queue = NSOperationQueue()
        
        // create an ParseOperation (NSOperation subclass) to parse the RSS feed data
        // so that the UI is not blocked
        let parser = ParseOperation(data: self.appListData!)
        
        parser.errorHandler = {parseError in
            dispatch_async(dispatch_get_main_queue()) {
                self.handleError(parseError)
            }
        }
        
        // Referencing parser from within its completionBlock would create a retain cycle.
        parser.completionBlock = {
            [weak parser] () in
            if parser?.appRecordList != nil {
                // The completion block may execute on any thread.  Because operations
                // involving the UI are about to be performed, make sure they execute
                // on the main thread.
                dispatch_async(dispatch_get_main_queue()) {
                    // The root rootViewController is the only child of the navigation
                    // controller, which is the window's rootViewController.
                    let rootViewController = (self.window!.rootViewController as! UINavigationController) .
                        topViewController as! RootViewController
                    
                    rootViewController.entries = parser!.appRecordList
                    
                    // tell our table view to reload its data, now that parsing has completed
                    rootViewController.tableView.reloadData()
                }
            }
            
            // we are finished with the queue and our ParseOperation
            self.queue = nil
        }
        
        self.queue?.addOperation(parser)
        
        // ownership of appListData has been transferred to the parse operation
        // and should no longer be referenced in this thread
        self.appListData = nil
    }
    
}