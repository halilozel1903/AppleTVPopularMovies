//
//  Theme.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

enum Theme {
    static let backdrop = UIColor(named: "Backdrop") ?? UIColor(red: 0.043, green: 0.047, blue: 0.063, alpha: 1)
    static let backdropTop = UIColor(red: 0.086, green: 0.102, blue: 0.149, alpha: 1)
    static let posterFill = UIColor(white: 1, alpha: 0.08)
    static let primaryText = UIColor.white
    static let secondaryText = UIColor(white: 1, alpha: 0.62)
    static let overviewText = UIColor(white: 1, alpha: 0.84)
    static let gold = UIColor(red: 0.961, green: 0.757, blue: 0.420, alpha: 1)
    static let focusRing = UIColor.white

    static let posterWidth: CGFloat = 280
    static let posterHeight: CGFloat = 420
    static let titleHeight: CGFloat = 66
    static let cardHeight: CGFloat = 498
    static let shelfSpacing: CGFloat = 36
    static let posterCornerRadius: CGFloat = 18
    static let focusScale: CGFloat = 1.06
    static let railHeaderHeight: CGFloat = 48
}
