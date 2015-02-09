//
//  ParseOperation.swift
//  LazyTableImages
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/03.
//
//
/*
     File: ParseOperation.h
     File: ParseOperation.m
 Abstract: NSOperation subclass for parsing the RSS feed.

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

import Foundation
class ParseOperation: NSOperation, NSXMLParserDelegate {
    
    // A block to call when an error is encountered during parsing.
    var errorHandler: (NSError -> Void)?
    
    // NSArray containing AppRecord instances for each entry parsed
    // from the input data.
    // Only meaningful after the operation has completed.
    // Redeclare appRecordList so we can modify it within this class
    private(set) var appRecordList: [AppRecord]?
    
    
    // string contants found in the RSS feed
    let kIDStr = "id"
    let kNameStr = "im:name"
    let kImageStr = "im:image"
    let kArtistStr = "im:artist"
    let kEntryStr = "entry"
    
    
    private var dataToParse: NSData?
    private var workingArray: [AppRecord]?
    private var workingEntry: AppRecord?
    private var workingPropertyString: String?
    private var elementsToParse: [String]
    private var storingCharacterData: Bool = false
    
    
    //MARK: -
    
    
    // -------------------------------------------------------------------------------
    //	initWithData:
    // -------------------------------------------------------------------------------
    // The initializer for this NSOperation subclass.
    init(data: NSData) {
        dataToParse = data
        elementsToParse = [kIDStr, kNameStr, kImageStr, kArtistStr]
    }
    
    // -------------------------------------------------------------------------------
    //	main
    //  Entry point for the operation.
    //  Given data to parse, use NSXMLParser and process all the top paid apps.
    // -------------------------------------------------------------------------------
    override func main() {
        // The default implemetation of the -start method sets up an autorelease pool
        // just before invoking -main however it does NOT setup an excption handler
        // before invoking -main.  If an exception is thrown here, the app will be
        // terminated.
        
        workingArray = []
        workingPropertyString = ""
        
        // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
        // desirable because it gives less control over the network, particularly in responding to
        // connection errors.
        //
        let parser = NSXMLParser(data: self.dataToParse)
        parser.delegate = self
        parser.parse()
        
        if !self.cancelled {
            // Set appRecordList to the result of our parsing
            self.appRecordList = self.workingArray
        }
        
        self.workingArray = nil
        self.workingPropertyString = nil
        self.dataToParse = nil
    }
    
    
    //MARK: - RSS processing
    
    // -------------------------------------------------------------------------------
    //	parser:didStartElement:namespaceURI:qualifiedName:attributes:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]!) {
        // entry: { id (link), im:name (app name), im:image (variable height) }
        //
        if elementName == kEntryStr {
            self.workingEntry = AppRecord()
        }
        self.storingCharacterData = find(self.elementsToParse, elementName) != nil
    }
    
    // -------------------------------------------------------------------------------
    //	parser:didEndElement:namespaceURI:qualifiedName:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if self.workingEntry != nil {
            if self.storingCharacterData {
                let trimmedString = self.workingPropertyString?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                self.workingPropertyString = ""
                switch elementName {
                case kIDStr:
                    self.workingEntry!.appURLString = trimmedString
                case kNameStr:
                    self.workingEntry!.appName = trimmedString
                case kImageStr:
                    self.workingEntry!.imageURLString = trimmedString
                case kArtistStr:
                    self.workingEntry!.artist = trimmedString
                default:
                    break
                }
            } else if elementName == kEntryStr {
                self.workingArray?.append(self.workingEntry!)
                self.workingEntry = nil
            }
        }
    }
    
    // -------------------------------------------------------------------------------
    //	parser:foundCharacters:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if storingCharacterData {
            self.workingPropertyString? += string
        }
    }
    
    // -------------------------------------------------------------------------------
    //	parser:parseErrorOccurred:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) {
        self.errorHandler?(parseError)
    }
    
}