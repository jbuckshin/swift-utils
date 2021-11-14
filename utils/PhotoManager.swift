//
//  PhotoManager.swift
//  Blend
//
//  Created by Joe Buckshin on 10/18/21.
//  Copyright © 2021 Joseph Buckshin. All rights reserved.
//

import Photos
import UIKit

class PhotoManager {

    private var albumName: String
    private var album: PHAssetCollection?
    private var albumCreationInProgress: Bool = false

    init(albumName: String) {
        self.albumName = albumName

        if let album = getAlbum() {
            self.album = album
            return
        }
    }
    
    func albumInitialized() -> Bool {
        if album != nil {
            return true
        }
        return false
    }

    private func getAlbum() -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle = %@", albumName)  // title or localized
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        
        print("collection \(collection.description)")
        
        return collection.firstObject ?? nil
    }

    private func createAlbum(completion: @escaping (Bool) -> ()) {
        
        print("creating album")
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
        }, completionHandler: { (result, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")
            } else {
                self.album = self.getAlbum()
                completion(result)
            }
        })
    }

    private func add(image: UIImage, completion: @escaping (Bool, Error?) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let album = self.album, let placeholder = assetChangeRequest.placeholderForCreatedAsset {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                let enumeration = NSArray(object: placeholder)
                albumChangeRequest?.addAssets(enumeration)
            }
        }, completionHandler: { (result, error) in
            completion(result, error)
        })
    }

    func save(_ image: UIImage, completion: @escaping (Bool, Error?) -> ()) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                // fail and redirect to app settings
                return
            }

            if let _ = self.album {
                self.add(image: image) { (result, error) in
                    completion(result, error)
                }
                return
            }

            
            
            if (self.albumCreationInProgress) { // avoid timing issues where we possibly create duplicate album names
                
                // just add, dont create the album.  there's got to be a better way to organize this code block
                self.add(image: image) { (result, error) in
                    self.albumCreationInProgress = false
                    completion(result, error)
                }
                return
            }
            
            self.albumCreationInProgress = true
            
            self.createAlbum(completion: { _ in
                self.add(image: image) { (result, error) in
                    self.albumCreationInProgress = false
                    completion(result, error)
                }
            })
        }
    }
}
