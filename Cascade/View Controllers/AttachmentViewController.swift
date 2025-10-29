//
//  AttachmentViewController.swift
//  MakingADiscordAPI
//
//  Created by JWI on 25/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix

class AttachmentViewController: UIViewController {
    public var attachment: UIView
    
    init(attachment: UIView) {
        self.attachment = attachment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        view.addSubview(attachment)
        attachment.pinToEdges(of: view)
    }
}
