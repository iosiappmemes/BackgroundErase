//
//  Photolibrary.swift
//  BackgroundErase
//
//  Created by iApp on 13/01/23.
//

import Photos
import UIKit

class CustomPhotoAlbum {

    static let albumName = "Eraser"
    static let sharedInstance = CustomPhotoAlbum()

    var assetCollection: PHAssetCollection!
    var albums: PHFetchResult = PHFetchResult<PHAsset>()


    init() {

        func fetchAssetCollectionForAlbum() -> PHAssetCollection! {

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbum.albumName)
            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

            if let firstObject: AnyObject = collection.firstObject {
                print(firstObject)
                return collection.firstObject
            }

            return nil
        }

        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CustomPhotoAlbum.albumName)
        }) { success, _ in
            if success {
                self.assetCollection = fetchAssetCollectionForAlbum()
            }
        }
    }

    func saveImage(image: UIImage) {

        if assetCollection == nil {
            return   // If there was an error upstream, skip the save.
        }

        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection, assets: self.albums)
            albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
        }, completionHandler: nil)
    }

}
