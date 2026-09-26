//
//  MovieCell.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

class MovieCell: UICollectionViewCell {
    
    // cell gosterilecek icerikler
    
    @IBOutlet weak var movieImage: UIImageView!
    @IBOutlet weak var movieName: UILabel!
    
    func configureCell(movie: Movie) {
        movieName.text = movie.title
        movieImage.image = nil

        guard let url = movie.posterURL,
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return
        }
        movieImage.image = image
    }
    
}
