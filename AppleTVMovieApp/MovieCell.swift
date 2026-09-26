//
//  MovieCell.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

class MovieCell: UICollectionViewCell {

    @IBOutlet weak var movieImage: UIImageView!
    @IBOutlet weak var movieName: UILabel!

    private var loadTask: Task<Void, Never>?
    private var representedID: Int?

    func configureCell(movie: Movie) {
        representedID = movie.id
        movieName.text = movie.title
        movieImage.image = nil
        loadTask?.cancel()

        guard let url = movie.posterURL else { return }
        let movieID = movie.id
        loadTask = Task { @MainActor [weak self] in
            guard let image = try? await ImageLoader.shared.image(for: url) else { return }
            guard let self = self, !Task.isCancelled, self.representedID == movieID else { return }
            self.movieImage.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadTask?.cancel()
        loadTask = nil
        representedID = nil
        movieImage.image = nil
    }
}
