//
//  DMVC+MessageAction.swift
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


//MARK: Message Action Functions
extension GuildTextViewController {
    func takeMessageAction(_ message: Message) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        applyGaussianBlur(to: containerView.layer, radius: 12)
        let messageActionView = MessageActionView(clientUser, message, self.channel!)
        messageActionView.alpha = 0
        messageActionView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        view.addSubview(messageActionView)
        messageActionView.translatesAutoresizingMaskIntoConstraints = false
        messageActionView.pinToCenter(of: view)
        CATransaction.commit()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            messageActionView.alpha = 1
            messageActionView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.containerView.isUserInteractionEnabled = false
            if let nav = UIApplication.shared.keyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 0
            }
        }
    }

    
    func endMessageAction() {
        let messageActionViews = self.view.subviews.compactMap({ $0 as? MessageActionView })
        
        guard !messageActionViews.isEmpty else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            for messageActionView in messageActionViews {
                messageActionView.alpha = 0
                messageActionView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            self.containerView.isUserInteractionEnabled = true
            self.containerView.layer.filters = nil
            
            if let nav = UIApplication.shared.windows.first?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 1
            }
        }, completion: { _ in
            for messageActionView in messageActionViews {
                messageActionView.removeFromSuperview()
            }
        })
    }
    
    func presentProfileView(for user: User, _ member: GuildMember? = nil) {
        guard let parentView = self.view else { return }
        let profile = ProfileView(user: user, member: member)
        
        // Set height and top offset
        let topOffset: CGFloat = self.navigationBarHeight
        let height = parentView.bounds.height - topOffset
        
        // Start off-screen
        profile.frame = CGRect(
            x: 0,
            y: parentView.bounds.height,
            width: parentView.bounds.width,
            height: height
        )
        
        parentView.addSubview(profile)
        profileView = profile
        
        // Animate in
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            profile.frame.origin.y = topOffset
            if let nav = UIApplication.shared.keyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 0
            }
        }, completion: nil)
    }


    func removeProfileView() {
        guard let profile = profileView, let parent = profile.superview else { return }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            profile.frame.origin.y = parent.bounds.height
            if let nav = UIApplication.shared.windows.first?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 1
            }
        }, completion: { _ in
            profile.removeFromSuperview()
            self.profileView = nil
        })
    }
}
