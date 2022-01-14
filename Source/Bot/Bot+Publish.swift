//
//  Bot+Publish.swift
//  FBTT
//
//  Created by Christoph on 7/8/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit
import Logger
import Bot
import SSB

typealias PublishBlobsCompletion = ((Blobs, Error?) -> Void)
typealias PrefetchCompletion = (Int, KeyValue) -> Void
// Convenience types to simplify writing completion closures.
typealias AboutCompletion = ((About?, Error?) -> Void)
typealias AboutsCompletion = (([About], Error?) -> Void)
typealias AddImageCompletion = ((Image?, Error?) -> Void)
typealias BlobsAddCompletion = ((BlobIdentifier, Error?) -> Void)
typealias BlobsStoreCompletion = ((URL?, Error?) -> Void)
typealias ContactCompletion = ((Contact?, Error?) -> Void)
typealias ContactsCompletion = (([Identity], Error?) -> Void)
typealias ErrorCompletion = ((Error?) -> Void)
typealias KeyValuesCompletion = ((KeyValues, Error?) -> Void)
typealias PaginatedCompletion = ((PaginatedKeyValueDataProxy, Error?) -> Void)
typealias HashtagCompletion = ((Hashtag?, Error?) -> Void)
typealias HashtagsCompletion = (([Hashtag], Error?) -> Void)
typealias PublishCompletion = ((MessageIdentifier, Error?) -> Void)
typealias RefreshCompletion = ((Error?, TimeInterval) -> Void)
typealias SecretCompletion = ((Secret?, Error?) -> Void)
typealias SyncCompletion = ((Error?, TimeInterval, Int) -> Void)
typealias ThreadCompletion = ((KeyValue?, PaginatedKeyValueDataProxy, Error?) -> Void)
typealias UIImageCompletion = ((Identifier?, UIImage?, Error?) -> Void)
typealias KnownPubsCompletion = (([KnownPub], Error?) -> Void)
typealias StatisticsCompletion = ((Statistics) -> Void)

extension Bot {

    func publish(_ post: Post,
                 with images: [UIImage] = [],
                 completion: @escaping ((MessageIdentifier, Error?) -> Void))
    {
        Thread.assertIsMainThread()

        // publish all images first
        self.prepare(images) {
            blobs, error in
            if Logger.shared.optional(error) { completion(Identifier.null, error); return }

            // mutate post to include blobs
            let postWithBlobs = post.copy(with: blobs)

            // publish post

            self.publish(content: postWithBlobs) {
                postIdentifier, error in
                if Logger.shared.optional(error) { completion(.null, error); return }
                completion(postIdentifier, nil)
            }
        }
    }

    func login(network: DataKey, hmacKey: DataKey?, secret: Secret, completion: @escaping ((Error?) -> Void)) {
        let servicePubs: [Identity] = Environment.Constellation.stars.map { $0.feed }
        login(network: network, hmacKey: hmacKey, secret: secret, servicePubs: servicePubs, completion: completion)
    }

    func block(_ identity: Identity, completion: @escaping ((MessageIdentifier, Error?) -> Void)) {
        let numberOfPublishedMessages = UInt(AppConfiguration.current?.numberOfPublishedMessages ?? 0)
        block(identity, numberOfPublishedMessages: numberOfPublishedMessages, completion: completion)
    }

    func unblock(_ identity: Identity, completion: @escaping ((MessageIdentifier, Error?) -> Void)) {
        let numberOfPublishedMessages = UInt(AppConfiguration.current?.numberOfPublishedMessages ?? 0)
        unblock(identity, numberOfPublishedMessages: numberOfPublishedMessages, completion: completion)
    }

    func follow(_ identity: Identity, completion: @escaping ((Contact?, Error?) -> Void)) {
        let numberOfPublishedMessages = UInt(AppConfiguration.current?.numberOfPublishedMessages ?? 0)
        follow(identity, numberOfPublishedMessages: numberOfPublishedMessages, completion: completion)
    }

    func unfollow(_ identity: Identity, completion: @escaping ((Contact?, Error?) -> Void)) {
        let numberOfPublishedMessages = UInt(AppConfiguration.current?.numberOfPublishedMessages ?? 0)
        unfollow(identity, numberOfPublishedMessages: numberOfPublishedMessages, completion: completion)
    }

    func publish(content: ContentCodable, completion: @escaping ((MessageIdentifier, Error?) -> Void)) {
        let numberOfPublishedMessages = AppConfiguration.current?.numberOfPublishedMessages ?? 0
        publish(content: content,
                numberOfPublishedMessages: UInt(numberOfPublishedMessages),
                completion: completion)
    }

    func sync(queue: DispatchQueue, peers: [Peer], completion: @escaping ((Error?, TimeInterval, Int) -> Void)) {
        sync(peers: peers) { error, timeInterval, newMessages in
            queue.async {
                completion(error, timeInterval, newMessages)
            }
        }
    }

    // will attempt to add all images to the blob-store and annotate them with metadata
    // will quit after first failure and return an error without models
    // if some of the images were published and later ones fail well
    // then doing this again will duplicate already published images
    func prepare(_ images: [UIImage],
                 completion: @escaping PublishBlobsCompletion)
    {
        Thread.assertIsMainThread()
        if images.isEmpty { completion([], nil); return }

        var blobs = [Int: Blob]()

        // TODO need to add Bot.publish(blobs)
        // TODO check all blobs before publish
        let datas = images.compactMap { $0.blobData() }
        // TODO need Bot error
        guard datas.count == images.count else { completion([], nil); return }

        for (index, data) in datas.enumerated() {
            let image = images[index]
            self.addBlob(data: data) {
                identifier, error in
                if let error = error { completion([], error); return }
                let metadata = Blob.Metadata.describing(image, mimeType: .jpeg, data: data)
                let blob = Blob(identifier: identifier, metadata: metadata)
                blobs[index] = blob
                if blobs.count == images.count {
                    let sortedBlobs = blobs.sorted(by: {$0.0 < $1.0})
                    completion(sortedBlobs.map{ $1 }, nil)
                }
            }
        }
    }
}

fileprivate extension UIImage {

    /// Convenience to return data representing the JPG
    /// compressed version of the image.  This assumes
    /// a max size and compression ratio that fits within
    /// the SSB blob max bytes.
    func blobData() -> Data? {
        guard let image = self.resized(toLargestDimension: 1000) else { return nil }
        guard let data = image.jpegData(compressionQuality: 0.5) else { return nil }
        return data
    }
}
