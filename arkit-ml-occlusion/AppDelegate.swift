//
//  AppDelegate.swift
//  arkit-ml-occlusion
//
//  Created by Alexander on 04/04/2019.
//  Copyright © 2019 Aleksandr Gutrits. All rights reserved.
//

import UIKit
import Fritz

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FritzCore.configure()
        return true
    }
}

