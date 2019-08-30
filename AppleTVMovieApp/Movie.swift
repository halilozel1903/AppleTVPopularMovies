//
//  Movie.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import Foundation

class Movie{
    
    let POSTER_URL_BASE = "https://image.tmdb.org/t/p/w500"
    
    var title : String!
    var overview : String!
    var posterPath : String!
    
    init(movieDictionary: Dictionary<String,AnyObject>) {
        
        if let title = movieDictionary["title"] as? String{
            
            self.title = title
        }
        
        if let overview = movieDictionary["overview"] as? String{
            self.overview = overview
        }
        
        if let path = movieDictionary["poster_path"] as? String{
            
            self.posterPath = "\(POSTER_URL_BASE)\(path)"
        }
    }
}
