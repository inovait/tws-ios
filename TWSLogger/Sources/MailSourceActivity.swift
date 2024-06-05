//
//  MailSourceActivity.swift
//  TWSLogger
//
//  Created by Luka Kit on 5. 6. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//
import MessageUI
import UIKit

public class MailActivityItemSource: NSObject, UIActivityItemSource {
    private let fileURL: URL
    private let emailSubject = "TWS - Logs"
    private let emailRecipients = ["luka.kit@inova.si", "miha.hozjan.si"]

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileURL
    }
    public func activityViewController(_ activityViewController: UIActivityViewController,
                                       itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return fileURL
    }
    public func activityViewController(_ activityViewController: UIActivityViewController,
                                       subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return emailSubject
    }

    public func activityViewController(_ activityViewController: UIActivityViewController,
                                       dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?)
    -> String {
        return "public.text"
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                activityViewControllerForActivityType activityType: UIActivity.ActivityType?)
    -> MFMailComposeViewController? {
        if activityType == .mail {
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.setSubject(emailSubject)
            mailComposeVC.setToRecipients(["luka.kit@inova.si"])

            do {
                let fileData = try Data(contentsOf: fileURL)
                mailComposeVC.addAttachmentData(fileData, mimeType: "text/plain", fileName: fileURL.lastPathComponent)
            } catch {
                // The file won't be attached
            }

            return mailComposeVC
        }
        return nil
    }
}
