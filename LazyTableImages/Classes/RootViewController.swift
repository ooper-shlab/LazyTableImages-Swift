//
//  RootViewController.swift
//  LazyTableImages
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/03.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Controller for the main table view of the LazyTable sample.
  This table view controller works off the AppDelege's data model.
  produce a three-stage lazy load:
  1. No data (i.e. an empty table)
  2. Text-only data from the model's RSS feed
  3. Images loaded over the network asynchronously

  This process allows for asynchronous loading of the table to keep the UI responsive.
  Stage 3 is managed by the AppRecord corresponding to each row/cell.

  Images are scaled to the desired height.
  If rapid scrolling is in progress, downloads do not begin until scrolling has ended.
 */

import UIKit
import QuartzCore.CALayer

@objc(RootViewController)
class RootViewController : UITableViewController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // the main data model for our UITableView
    var entries: [AppRecord]?
    
    let kCustomRowCount = 7
    
    let CellIdentifier = "LazyTableCell"
    let PlaceHolderCellIdentifier = "PlaceholderCell"
    
    
    //MARK: -
    
    // the set of IconDownloader objects for each app
    private var imageDownloadsInProgress: [NSIndexPath: IconDownloader] = [:]
    
    
    //MARK: -
    
    // -------------------------------------------------------------------------------
    //	viewDidLoad
    // -------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageDownloadsInProgress = [:]
    }
    
    // -------------------------------------------------------------------------------
    //	terminateAllDownloads
    // -------------------------------------------------------------------------------
    private func terminateAllDownloads() {
        // terminate all pending download connections
        let allDownloads = self.imageDownloadsInProgress.values
        for download in allDownloads {download.cancelDownload()}
        
        self.imageDownloadsInProgress.removeAll(keepCapacity: false)
    }
    
    // -------------------------------------------------------------------------------
    //	dealloc
    //  If this view controller is going away, we need to cancel all outstanding downloads.
    // -------------------------------------------------------------------------------
    deinit {
        // terminate all pending download connections
        self.terminateAllDownloads()
    }
    
    // -------------------------------------------------------------------------------
    //	didReceiveMemoryWarning
    // -------------------------------------------------------------------------------
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // terminate all pending download connections
        self.terminateAllDownloads()
    }
    
    
    //MARK: - UITableViewDataSource
    
    // -------------------------------------------------------------------------------
    //	tableView:numberOfRowsInSection:
    //  Customize the number of rows in the table view.
    // -------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = (self.entries?.count ?? 0)
        
        // if there's no data yet, return enough rows to fill the screen
        if count == 0 {
            return kCustomRowCount
        }
        return count
    }
    
    // -------------------------------------------------------------------------------
    //	tableView:cellForRowAtIndexPath:
    // -------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        
        let nodeCount = self.entries?.count ?? 0
        
        if nodeCount == 0 && indexPath.row == 0 {
            // add a placeholder cell while waiting on table data
            cell = tableView.dequeueReusableCellWithIdentifier(PlaceHolderCellIdentifier, forIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
            
            // Leave cells empty if there's no data yet
            if nodeCount > 0 {
                // Set up the cell representing the app
                let appRecord = self.entries![Int(indexPath.row)] as AppRecord
                
                cell!.textLabel!.text = appRecord.appName
                cell!.detailTextLabel?.text = appRecord.artist
                
                // Only load cached images; defer new downloads until scrolling ends
                if appRecord.appIcon == nil {
                    if !self.tableView.dragging && !self.tableView.decelerating {
                        self.startIconDownload(appRecord, forIndexPath: indexPath)
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    cell!.imageView!.image = UIImage(named: "Placeholder.png")!
                } else {
                    cell!.imageView!.image = appRecord.appIcon
                }
            }
        }
        
        return cell!
    }
    
    
    //MARK: - Table cell image support
    
    // -------------------------------------------------------------------------------
    //	startIconDownload:forIndexPath:
    // -------------------------------------------------------------------------------
    private func startIconDownload(appRecord: AppRecord, forIndexPath indexPath: NSIndexPath) {
        var iconDownloader = self.imageDownloadsInProgress[indexPath]
        if iconDownloader == nil {
            iconDownloader = IconDownloader()
            iconDownloader!.appRecord = appRecord
            iconDownloader!.completionHandler = {
                
                let cell = self.tableView.cellForRowAtIndexPath(indexPath)
                
                // Display the newly loaded image
                cell?.imageView?.image = appRecord.appIcon
                
                // Remove the IconDownloader from the in progress list.
                // This will result in it being deallocated.
                self.imageDownloadsInProgress.removeValueForKey(indexPath)
                
            }
            self.imageDownloadsInProgress[indexPath] = iconDownloader
            iconDownloader!.startDownload()
        }
    }
    
    // -------------------------------------------------------------------------------
    //	loadImagesForOnscreenRows
    //  This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    // -------------------------------------------------------------------------------
    private func loadImagesForOnscreenRows() {
        if (self.entries?.count ?? 0) > 0 {
            let visiblePaths = self.tableView.indexPathsForVisibleRows!
            for indexPath in visiblePaths as [NSIndexPath] {
                let appRecord = self.entries![indexPath.row]
                
                // Avoid the app icon download if the app already has an icon
                if appRecord.appIcon == nil {
                    self.startIconDownload(appRecord, forIndexPath: indexPath)
                }
            }
        }
    }
    
    
    //MARK: - UIScrollViewDelegate
    
    // -------------------------------------------------------------------------------
    //	scrollViewDidEndDragging:willDecelerate:
    //  Load images for all onscreen rows when scrolling is finished.
    // -------------------------------------------------------------------------------
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }
    
    // -------------------------------------------------------------------------------
    //	scrollViewDidEndDecelerating:scrollView
    //  When scrolling stops, proceed to load the app icons that are on screen.
    // -------------------------------------------------------------------------------
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }
    
}