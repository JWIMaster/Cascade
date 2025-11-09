//
//  AppDelegate.swift
//  MakingADiscordAPI
//
//  Created by JWI on 15/10/2025.
//

import UIKit
import iOS6BarFix
import LiveFrost
import FoundationCompatKit
import UIKitExtensions
import SwiftcordLegacy

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        var rootVC: UIViewController
        var navController: UINavigationController
        AvatarCache.shared.memoryCache.countLimit = 20
        print(UIColor.black.argbInt)
        
        if token != nil {
            rootVC = ViewController()
            navController = CustomNavigationController(rootViewController: rootVC)
            
            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(navController, true)

            window?.clipsToBounds = false
            window?.frame = UIScreen.main.bounds
            window?.rootViewController = navController
            window?.makeKeyAndVisible()
            return true
        } else {
            rootVC = AuthenticationViewController()
            window?.rootViewController = rootVC
            window?.makeKeyAndVisible()
            return true
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        clientUser.saveCache()
    }
    
    
}


