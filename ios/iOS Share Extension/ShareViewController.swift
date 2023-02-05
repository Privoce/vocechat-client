//
//  ShareViewController.swift
//  iOS Share Extension
//
//  Created by Vincent Wang on 2/4/23.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)

           // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
           if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
               if let contents = content.attachments {
                   for (index, attachment) in (contents).enumerated() {
                       print("****** here ******")
                    
//                       if attachment.hasItemConformingToTypeIdentifier(imageContentType) {
//                           handleImages(content: content, attachment: attachment, index: index)
//                       } else if attachment.hasItemConformingToTypeIdentifier(textContentType) {
//                           handleText(content: content, attachment: attachment, index: index)
//                       } else if attachment.hasItemConformingToTypeIdentifier(fileURLType) {
//                           handleFiles(content: content, attachment: attachment, index: index)
//                       } else if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
//                           handleUrl(content: content, attachment: attachment, index: index)
//                       } else if attachment.hasItemConformingToTypeIdentifier(videoContentType) {
//                           handleVideos(content: content, attachment: attachment, index: index)
//                       }
                   }
               }
           }
       }

}
