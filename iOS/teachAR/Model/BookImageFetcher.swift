//
//  BookImageFetcher.swift
//  leARn
//
//  Created by Avery on 7/28/18.
//  Copyright © 2018 Avery Lamp. All rights reserved.
//

import Foundation
import FirebaseFirestore

class BookImageFetcher{
    
    static let sharedInstance = BookImageFetcher()
    private init() {} //This prevents others from using the default '()' initializer for this class.
    
    

    
    func getImagesForBook() -> Array<URL>{
        return Array<URL> ()
    }
    
    
    

}
