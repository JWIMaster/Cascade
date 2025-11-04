//
//  DMVC+Input.swift
//  Cascade
//
//  Created by JWI on 31/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import LiveFrost

//MARK: View input functions
extension GuildTextViewController {
    func setupInputView(for channel: GuildText) {
        textInputView = InputView(channel: channel, snapshotView: view)
        guard let textInputView = textInputView else {
            return
        }

        containerView.addSubview(textInputView)
        textInputView.translatesAutoresizingMaskIntoConstraints = false
        
        textInputView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        textInputView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        textInputView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20).isActive = true
        
        view.layoutIfNeeded()
        scrollView.contentInset.bottom = textInputView.bounds.height + 10
        scrollView.contentInset.top = (navigationController?.navigationBar.frame.height)!
        
        scrollView.layoutIfNeeded()
        scrollToBottom(animated: false)
        
        initialViewSetupComplete = true
    }
}
