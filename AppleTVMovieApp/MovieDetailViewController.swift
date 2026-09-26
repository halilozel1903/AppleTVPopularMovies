//
//  MovieDetailViewController.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class MovieDetailViewController: UIViewController {
    private let preview: Movie
    private let service: MovieService
    private var loadTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?

    private let gradientLayer = CAGradientLayer()
    private let backButton = UIButton(type: .system)
    private let posterView = UIImageView()
    private let placeholderView = UIImageView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let overviewLabel = UILabel()
    private let contentRow = UIStackView()
    private let textScroll = UIScrollView()
    private let textStack = UIStackView()
    private let statusContainer = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    init(movie: Movie, service: MovieService) {
        self.preview = movie
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Movie detail is created in code.")
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if !retryButton.isHidden {
            return [retryButton]
        }
        return [backButton]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = preview.title
        overrideUserInterfaceStyle = .dark
        configureAppearance()
        configureBackButton()
        configureContent()
        configureStatus()
        installConstraints()
        loadDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations { [weak self] in
            guard let self = self else { return }
            for button in [self.backButton, self.retryButton] {
                let scale: CGFloat = button.isFocused ? 1.06 : 1
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }

    private func configureAppearance() {
        view.backgroundColor = Theme.backdrop
        gradientLayer.colors = [Theme.backdropTop.cgColor, Theme.backdrop.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureBackButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Movies"
        config.image = UIImage(systemName: "chevron.backward")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.14)
        config.baseForegroundColor = Theme.primaryText
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 22, bottom: 12, trailing: 26)
        backButton.configuration = config
        backButton.accessibilityLabel = "Back to movies"
        backButton.accessibilityIdentifier = "detail.back"
        backButton.addTarget(self, action: #selector(backTapped), for: .primaryActionTriggered)
    }

    private func configureContent() {
        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true
        posterView.backgroundColor = Theme.posterFill
        posterView.layer.cornerRadius = Theme.posterCornerRadius
        posterView.translatesAutoresizingMaskIntoConstraints = false

        placeholderView.image = UIImage(systemName: "film")
        placeholderView.tintColor = UIColor(white: 1, alpha: 0.45)
        placeholderView.contentMode = .scaleAspectFit
        placeholderView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        posterView.addSubview(placeholderView)

        eyebrowLabel.attributedText = NSAttributedString(
            string: "MOVIE",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: Theme.secondaryText,
                .kern: 3.5
            ]
        )
        eyebrowLabel.accessibilityLabel = "Movie"

        titleLabel.font = UIFont.systemFont(ofSize: 56, weight: .bold)
        titleLabel.textColor = Theme.primaryText
        titleLabel.numberOfLines = 3

        metaLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        metaLabel.textColor = Theme.gold

        overviewLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        overviewLabel.textColor = Theme.overviewText
        overviewLabel.numberOfLines = 0

        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 12
        textStack.addArrangedSubview(eyebrowLabel)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(metaLabel)
        textStack.addArrangedSubview(overviewLabel)
        textStack.setCustomSpacing(18, after: metaLabel)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        textScroll.translatesAutoresizingMaskIntoConstraints = false
        textScroll.showsVerticalScrollIndicator = true
        textScroll.clipsToBounds = true
        textScroll.addSubview(textStack)

        let posterHolder = UIView()
        posterHolder.translatesAutoresizingMaskIntoConstraints = false
        posterHolder.addSubview(posterView)
        NSLayoutConstraint.activate([
            posterView.topAnchor.constraint(equalTo: posterHolder.topAnchor),
            posterView.leadingAnchor.constraint(equalTo: posterHolder.leadingAnchor),
            posterView.trailingAnchor.constraint(equalTo: posterHolder.trailingAnchor),
            posterView.bottomAnchor.constraint(equalTo: posterHolder.bottomAnchor),
            posterView.widthAnchor.constraint(equalToConstant: 360),
            posterView.heightAnchor.constraint(equalToConstant: 540),
            placeholderView.centerXAnchor.constraint(equalTo: posterView.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: posterView.centerYAnchor),
            placeholderView.widthAnchor.constraint(equalToConstant: 64),
            placeholderView.heightAnchor.constraint(equalToConstant: 64)
        ])

        posterHolder.setContentHuggingPriority(.required, for: .horizontal)
        posterHolder.setContentCompressionResistancePriority(.required, for: .horizontal)
        textScroll.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textScroll.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentRow.axis = .horizontal
        contentRow.alignment = .top
        contentRow.spacing = 56
        contentRow.addArrangedSubview(posterHolder)
        contentRow.addArrangedSubview(textScroll)
        contentRow.isHidden = true
    }

    private func configureStatus() {
        spinner.color = .white
        spinner.hidesWhenStopped = true

        statusLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        statusLabel.textColor = Theme.primaryText
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = 760
        statusLabel.accessibilityIdentifier = "detail.status"

        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = Theme.backdrop
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 36, bottom: 16, trailing: 36)
        retryButton.configuration = config
        retryButton.accessibilityIdentifier = "detail.retry"
        retryButton.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)

        statusContainer.axis = .vertical
        statusContainer.alignment = .center
        statusContainer.spacing = 22
        statusContainer.addArrangedSubview(spinner)
        statusContainer.addArrangedSubview(statusLabel)
        statusContainer.addArrangedSubview(retryButton)
    }

    private func installConstraints() {
        [backButton, contentRow, statusContainer].forEach { item in
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor),

            contentRow.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 36),
            contentRow.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            contentRow.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            contentRow.bottomAnchor.constraint(lessThanOrEqualTo: guide.bottomAnchor),

            textScroll.heightAnchor.constraint(equalToConstant: 540),

            textStack.topAnchor.constraint(equalTo: textScroll.contentLayoutGuide.topAnchor),
            textStack.leadingAnchor.constraint(equalTo: textScroll.contentLayoutGuide.leadingAnchor),
            textStack.trailingAnchor.constraint(equalTo: textScroll.contentLayoutGuide.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: textScroll.contentLayoutGuide.bottomAnchor),
            textStack.widthAnchor.constraint(equalTo: textScroll.frameLayoutGuide.widthAnchor),

            statusContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 24),
            statusLabel.widthAnchor.constraint(equalToConstant: 760)
        ])
    }

    private func loadDetails() {
        loadTask?.cancel()
        showLoading()
        let movieID = preview.id
        loadTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let movie = try await self.service.movieDetails(id: movieID)
                guard !Task.isCancelled else { return }
                self.showMovie(movie)
            } catch is CancellationError {
                return
            } catch let error as URLError where error.code == .cancelled {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self.showMessage(self.message(for: error), retry: true)
            }
        }
    }

    private func showMovie(_ movie: Movie) {
        statusContainer.isHidden = true
        spinner.stopAnimating()
        contentRow.isHidden = false
        titleLabel.text = movie.title
        metaLabel.text = movie.metaText
        metaLabel.isHidden = movie.metaText.isEmpty
        overviewLabel.text = movie.overviewText
        loadPoster(for: movie)
        refreshFocus()
    }

    private func showLoading() {
        contentRow.isHidden = true
        imageTask?.cancel()
        posterView.image = nil
        statusContainer.isHidden = false
        statusLabel.text = "Loading \(preview.title)…"
        spinner.isHidden = false
        spinner.startAnimating()
        retryButton.isHidden = true
        refreshFocus()
    }

    private func showMessage(_ text: String, retry: Bool) {
        contentRow.isHidden = true
        imageTask?.cancel()
        statusContainer.isHidden = false
        statusLabel.text = text
        spinner.stopAnimating()
        spinner.isHidden = true
        retryButton.isHidden = !retry
        refreshFocus()
    }

    private func loadPoster(for movie: Movie) {
        imageTask?.cancel()
        posterView.image = nil
        placeholderView.isHidden = false
        guard let url = movie.posterURL else { return }
        imageTask = Task { @MainActor [weak self] in
            guard let image = try? await ImageLoader.shared.image(for: url) else { return }
            guard let self = self, !Task.isCancelled else { return }
            self.posterView.image = image
            self.placeholderView.isHidden = true
        }
    }

    private func message(for error: Error) -> String {
        if let serviceError = error as? MovieServiceError {
            return serviceError.localizedDescription
        }
        if error is URLError {
            return "Check the network connection and try again."
        }
        return "Something went wrong while loading this movie."
    }

    private func refreshFocus() {
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func retryTapped() {
        loadDetails()
    }
}
