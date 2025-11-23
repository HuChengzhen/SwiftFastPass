//
//  File+ResolvedURL.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2025/11/23.
//  Copyright © 2025 huchengzhen. All rights reserved.
//

extension File {
    func resolvedURL() -> URL? {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: [.withoutUI],   // iOS ONLY
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return url
        } catch {
            print("Failed to resolve bookmark for file \(name): \(error)")
            return nil
        }
    }
}

