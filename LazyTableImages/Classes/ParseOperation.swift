//
//  ParseOperation.swift
//  LazyTableImages
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/03.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 NSOperation subclass for parsing the RSS feed.
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
        let parser = NSXMLParser(data: self.dataToParse!)
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
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        // entry: { id (link), im:name (app name), im:image (variable height) }
        //
        if elementName == kEntryStr {
            self.workingEntry = AppRecord()
        }
        self.storingCharacterData = self.elementsToParse.indexOf(elementName) != nil
    }
    
    // -------------------------------------------------------------------------------
    //	parser:didEndElement:namespaceURI:qualifiedName:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if self.workingEntry != nil {
            if self.storingCharacterData {
                let trimmedString =
                self.workingPropertyString?.stringByTrimmingCharactersInSet(
                    NSCharacterSet.whitespaceAndNewlineCharacterSet())
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
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if storingCharacterData {
            self.workingPropertyString? += string
        }
    }
    
    // -------------------------------------------------------------------------------
    //	parser:parseErrorOccurred:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        self.errorHandler?(parseError)
    }
    
}