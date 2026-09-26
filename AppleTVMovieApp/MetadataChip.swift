//
//  MetadataChip.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class MetadataChip: UIView {
    private let label = UILabel()
    private let emphasized: Bool

    init(emphasized: Bool) {
        self.emphasized = emphasized
        super.init(frame: .zero)
        backgroundColor = emphasized
            ? Theme.gold.withAlphaComponent(0.2)
            : UIColor(white: 1, alpha: 0.14)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = emphasized
            ? Theme.gold.withAlphaComponent(0.55).cgColor
            : UIColor(white: 1, alpha: 0.16).cgColor

        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.textColor = emphasized ? Theme.gold : Theme.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("Chips are created in code.")
    }

    func setText(_ text: String?) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        label.text = trimmed
        isHidden = trimmed.isEmpty
    }
}
