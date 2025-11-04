//
//  WebsocketFunctions.swift
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


//MARK: Gateway functions
extension DMViewController {
    ///Attach websocket watchers to do realtime message events
    func attachGatewayObservers() {
        guard let gateway = clientUser.gateway else { return }

        // Assign closures
        gateway.onMessageCreate = { [weak self] message in
            self?.createMessage(message)
        }
        gateway.onMessageUpdate = { [weak self] message in
            self?.updateMessage(message)
        }
        gateway.onMessageDelete = { [weak self] message in
            self?.deleteMessage(message)
        }
    }
    
    
    //Websocket create message function
    func createMessage(_ message: Message) {
        //Unwrap optionals and check if the stack already contains the message we are about to add
        if let messageID = message.id, let userID = message.author?.id, !messageIDsInStack.contains(messageID), self.dm?.id == message.channelID {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return }
                self.messageStack.addArrangedSubview(MessageView(clientUser, message: message))
                self.messageIDsInStack.insert(messageID)
                //If it's a new user, add it to the list of users
                if !self.userIDsInStack.contains(userID) { self.userIDsInStack.insert(userID) }
                
                self.scrollView.layoutIfNeeded()
                //self.scrollToBottom(animated: true)
            }
        }
    }
    
    func deleteMessage(_ message: Message) {
        for view in messageStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        self.messageStack.removeArrangedSubview(messageView)
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
    }
    
    func updateMessage(_ message: Message) {
        for view in messageStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        messageView.updateMessage(message)
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
    }
}
