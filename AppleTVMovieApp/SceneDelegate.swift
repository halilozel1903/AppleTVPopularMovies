//
//  SceneDelegate.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = Theme.backdrop
        window.overrideUserInterfaceStyle = .dark
        let navigation = UINavigationController(rootViewController: ViewController())
        navigation.setNavigationBarHidden(true, animated: false)
        navigation.view.backgroundColor = Theme.backdrop
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        self.window = window
    }
}
