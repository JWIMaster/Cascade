//
//  AuthenticationView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 19/10/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy

class AuthenticationViewController: UIViewController, UITextViewDelegate {
    let tokenInput = UITextView()
    let startButton = UIButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        tokenInput.translatesAutoresizingMaskIntoConstraints = false
        tokenInput.backgroundColor = .gray
        tokenInput.textColor = .black
        tokenInput.font = UIFont.systemFont(ofSize: 18)
        tokenInput.isScrollEnabled = false
        tokenInput.delegate = self
        view.addSubview(tokenInput)
        tokenInput.pinToCenter(of: view)
        
        startButton.titleLabel?.font = .systemFont(ofSize: 18)
        startButton.setTitle("Enter", for: .normal)
        startButton.setTitleColor(.black, for: .normal)
        startButton.addAction(for: .touchUpInside) {
            let trimmed = self.tokenInput.text.trimmingCharacters(in: .whitespacesAndNewlines)
            token = trimmed
            hasAuthenticated = "true"
            let startVC = ViewController()
            let navController = CustomNavigationController(rootViewController: startVC)
            UIApplication.shared.keyWindow?.rootViewController = navController
        }
        view.addSubview(startButton)
        tokenInput.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.1).isActive = true
        tokenInput.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        startButton.leadingAnchor.constraint(equalTo: tokenInput.trailingAnchor, constant: 10).isActive = true
        startButton.centerYAnchor.constraint(equalTo: tokenInput.centerYAnchor).isActive = true
    }
    
    func setupSubviews() {
        
    }
    
    func setupConstraints() {
        
    }
}




