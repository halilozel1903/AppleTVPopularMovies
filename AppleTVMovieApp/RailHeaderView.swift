//
//  RailHeaderView.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class RailHeaderView: UICollectionReusableView {
    private let accent = UIView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        accent.backgroundColor = Theme.gold
        accent.layer.cornerRadius = 2
        accent.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        titleLabel.textColor = Theme.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accent)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            accent.leadingAnchor.constraint(equalTo: leadingAnchor),
            accent.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            accent.widthAnchor.constraint(equalToConstant: 4),
            accent.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: accent.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .header
    }

    required init?(coder: NSCoder) {
        fatalError("Rail headers are created in code.")
    }

    func configure(title: String) {
        titleLabel.text = title
        accessibilityLabel = title
    }
}
