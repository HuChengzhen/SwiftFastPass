//
//  File.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit

class File: NSObject, NSCoding {

    let name: String
    private(set) var bookmark: Data
    var image: UIImage?
    private(set) var password: String?
    private(set) var keyFileContent: Data?
    
    static var files = loadFiles()
    
    init(name: String, bookmark: Data) {
        self.name = name
        self.bookmark = bookmark
    }
    
    func updateBookmark(_ bookmark: Data) {
        self.bookmark = bookmark
    }
    
    
    func attach(password: String?, keyFileContent: Data?) {
        self.password = password
        self.keyFileContent = keyFileContent
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(bookmark, forKey: "bookmark")
        coder.encode(image, forKey: "image")
        coder.encode(password, forKey: "password")
        coder.encode(keyFileContent, forKey: "keyFileContent")
    }
    
    required convenience init?(coder: NSCoder) {
        let name = coder.decodeObject(forKey: "name") as! String
        let bookmark = coder.decodeObject(forKey: "bookmark") as! Data
        let image = coder.decodeObject(forKey: "image") as? UIImage
        let password = coder.decodeObject(forKey: "password") as? String
        let keyFileContent = coder.decodeObject(forKey: "keyFileContent") as? Data
        self.init(name: name, bookmark: bookmark)
        self.image = image
        attach(password: password, keyFileContent: keyFileContent)
    }
    
    private static let archiveURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent("files")
        return archiveURL
    }()
    
    static func save() {
        let success = NSKeyedArchiver.archiveRootObject(files, toFile: archiveURL.path)
        if (!success) {
            print("File.save failed")
        }
    }
    
    static func loadFiles() -> [File] {
        return (NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? [File]) ?? []
    }
}
