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
    
    func configureCell(movie: Movie) {
        
        if let title = movie.title{
            
            movieName.text = title
        }
        
        if let path = movie.posterPath{
            
            let url = NSURL(string: path)!
            let data = NSData(contentsOf: url as URL)!
            let image = UIImage(data: data as Data)
            self.movieImage.image = image
        }
    }
    
}
