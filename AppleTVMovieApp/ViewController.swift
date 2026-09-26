//
//  ViewController.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

final class ViewController: UIViewController, UICollectionViewDelegate {
    private enum Section {
        case shelf
    }

    private let service = MovieService()
    private var loadTask: Task<Void, Never>?
    private var movies: [Movie] = []
    private var appliedSideInset: CGFloat = -1
    private var dataSource: UICollectionViewDiffableDataSource<Section, Movie>!

    private let gradientLayer = CAGradientLayer()
    private let topStack = UIStackView()
    private let headerStack = UIStackView()
    private let titleRow = UIStackView()
    private let heroStack = UIStackView()
    private let eyebrowLabel = UILabel()
    private let screenTitleLabel = UILabel()
    private let countLabel = UILabel()
    private let focusedTitleLabel = UILabel()
    private let metaLabel = UILabel()
    private let overviewLabel = UILabel()
    private let statusContainer = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private var collectionView: UICollectionView!

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        guard isViewLoaded, collectionView != nil else {
            return super.preferredFocusEnvironments
        }
        if !retryButton.isHidden {
            return [retryButton]
        }
        if !collectionView.isHidden {
            return [collectionView]
        }
        return super.preferredFocusEnvironments
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Popular Movies"
        overrideUserInterfaceStyle = .dark
        configureAppearance()
        configureHeader()
        configureHero()
        configureStatus()
        configureCollection()
        configureDataSource()
        installConstraints()
        showLoading()
        loadMovies()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        installShelfLayoutIfNeeded()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        guard let indexPath = context.nextFocusedIndexPath, movies.indices.contains(indexPath.item) else { return }
        let movie = movies[indexPath.item]
        coordinator.addCoordinatedAnimations { [weak self] in
            self?.showFocusedMovie(movie)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        let detail = MovieDetailViewController(movie: movies[indexPath.item], service: service)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func configureAppearance() {
        view.backgroundColor = Theme.backdrop
        gradientLayer.colors = [Theme.backdropTop.cgColor, Theme.backdrop.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureHeader() {
        eyebrowLabel.attributedText = NSAttributedString(
            string: "POPULAR",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: Theme.secondaryText,
                .kern: 3.5
            ]
        )
        eyebrowLabel.accessibilityLabel = "Popular"

        screenTitleLabel.text = "Movies"
        screenTitleLabel.font = UIFont.systemFont(ofSize: 64, weight: .bold)
        screenTitleLabel.textColor = Theme.primaryText
        screenTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        countLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        countLabel.textColor = Theme.secondaryText
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 16
        titleRow.addArrangedSubview(screenTitleLabel)
        titleRow.addArrangedSubview(spacer)
        titleRow.addArrangedSubview(countLabel)

        headerStack.axis = .vertical
        headerStack.alignment = .fill
        headerStack.spacing = 6
        headerStack.addArrangedSubview(eyebrowLabel)
        headerStack.addArrangedSubview(titleRow)
    }

    private func configureHero() {
        focusedTitleLabel.font = UIFont.systemFont(ofSize: 42, weight: .semibold)
        focusedTitleLabel.textColor = Theme.primaryText
        focusedTitleLabel.numberOfLines = 1
        focusedTitleLabel.lineBreakMode = .byTruncatingTail
        focusedTitleLabel.isAccessibilityElement = false

        metaLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        metaLabel.textColor = Theme.gold
        metaLabel.isAccessibilityElement = false

        overviewLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        overviewLabel.textColor = Theme.overviewText
        overviewLabel.numberOfLines = 2
        overviewLabel.lineBreakMode = .byTruncatingTail
        overviewLabel.isAccessibilityElement = false

        heroStack.axis = .vertical
        heroStack.alignment = .fill
        heroStack.spacing = 8
        heroStack.addArrangedSubview(focusedTitleLabel)
        heroStack.addArrangedSubview(metaLabel)
        heroStack.addArrangedSubview(overviewLabel)
        heroStack.setCustomSpacing(14, after: metaLabel)
        heroStack.isHidden = true
    }

    private func configureStatus() {
        spinner.color = .white
        spinner.hidesWhenStopped = true

        statusLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        statusLabel.textColor = Theme.primaryText
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = 760
        statusLabel.accessibilityIdentifier = "catalog.status"

        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.baseBackgroundColor = .white
        config.baseForegroundColor = Theme.backdrop
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 36, bottom: 16, trailing: 36)
        retryButton.configuration = config
        retryButton.accessibilityIdentifier = "catalog.retry"
        retryButton.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)

        statusContainer.axis = .vertical
        statusContainer.alignment = .center
        statusContainer.spacing = 22
        statusContainer.addArrangedSubview(spinner)
        statusContainer.addArrangedSubview(statusLabel)
        statusContainer.addArrangedSubview(retryButton)
    }

    private func configureCollection() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout(sideInset: 90))
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "catalog.shelf"
        appliedSideInset = 90
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<MovieCell, Movie> { cell, _, movie in
            cell.configure(with: movie)
        }
        dataSource = UICollectionViewDiffableDataSource<Section, Movie>(collectionView: collectionView) {
            collectionView, indexPath, movie in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: movie)
        }
    }

    private func installConstraints() {
        topStack.axis = .vertical
        topStack.alignment = .fill
        topStack.spacing = 28
        topStack.addArrangedSubview(headerStack)
        topStack.addArrangedSubview(heroStack)

        let arrangedViews: [UIView] = [topStack, collectionView, statusContainer]
        arrangedViews.forEach { item in
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            topStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            topStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            statusContainer.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            statusContainer.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            statusContainer.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor),
            statusContainer.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 760)
        ])
    }

    private func installShelfLayoutIfNeeded() {
        let side = view.safeAreaInsets.left
        guard side > 0, side != appliedSideInset else { return }
        appliedSideInset = side
        collectionView.setCollectionViewLayout(makeLayout(sideInset: side), animated: false)
    }

    private func makeLayout(sideInset: CGFloat) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(Theme.posterWidth),
                heightDimension: .fractionalHeight(1)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(Theme.posterWidth),
                heightDimension: .absolute(Theme.cardHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = Theme.shelfSpacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 32, leading: sideInset, bottom: 28, trailing: sideInset)
            section.contentInsetsReference = .none
            return section
        }
    }

    private func loadMovies() {
        loadTask?.cancel()
        showLoading()
        loadTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let results = try await self.service.popularMovies()
                guard !Task.isCancelled else { return }
                self.showShelf(self.uniqueMovies(results))
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

    private func uniqueMovies(_ movies: [Movie]) -> [Movie] {
        var seen = Set<Int>()
        return movies.filter { seen.insert($0.id).inserted }
    }

    private func showShelf(_ movies: [Movie]) {
        guard let first = movies.first else {
            self.movies = []
            showMessage("No popular movies to show right now.", retry: true)
            return
        }

        self.movies = movies
        statusContainer.isHidden = true
        spinner.stopAnimating()
        collectionView.isHidden = false
        heroStack.isHidden = false
        countLabel.isHidden = false
        countLabel.text = movies.count == 1 ? "1 title" : "\(movies.count) titles"
        showFocusedMovie(first)

        var snapshot = NSDiffableDataSourceSnapshot<Section, Movie>()
        snapshot.appendSections([.shelf])
        snapshot.appendItems(movies, toSection: .shelf)
        dataSource.apply(snapshot, animatingDifferences: false)
        refreshFocus()
    }

    private func showFocusedMovie(_ movie: Movie) {
        focusedTitleLabel.text = movie.title
        metaLabel.text = movie.metaText
        metaLabel.isHidden = movie.metaText.isEmpty
        overviewLabel.text = movie.overviewText
    }

    private func showLoading() {
        collectionView.isHidden = true
        heroStack.isHidden = true
        countLabel.isHidden = true
        statusContainer.isHidden = false
        statusLabel.text = "Loading popular movies…"
        spinner.isHidden = false
        spinner.startAnimating()
        retryButton.isHidden = true
        refreshFocus()
    }

    private func showMessage(_ text: String, retry: Bool) {
        collectionView.isHidden = true
        heroStack.isHidden = true
        countLabel.isHidden = true
        statusContainer.isHidden = false
        statusLabel.text = text
        spinner.stopAnimating()
        spinner.isHidden = true
        retryButton.isHidden = !retry
        refreshFocus()
    }

    private func message(for error: Error) -> String {
        if let serviceError = error as? MovieServiceError {
            return serviceError.localizedDescription
        }
        if error is URLError {
            return "Check the network connection and try again."
        }
        return "Something went wrong while loading movies."
    }

    private func refreshFocus() {
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    @objc private func retryTapped() {
        loadMovies()
    }
}
