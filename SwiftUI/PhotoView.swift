//
//  PhotoView.swift
//  SwiftUIExample
//
//  Created by Silence on 2023/9/8.
//  Copyright © 2023 洪欣. All rights reserved.
//

import SwiftUI
import HXPhotoPicker

@available(iOS 14.0, *)
struct PhotoView: View {
    
    let asset: Asset
    let imageSize: CGSize
    
    var body: some View {
        ZStack {
            Image(uiImage: asset.result.image)
                .resizable()
                .scaledToFill()
                .frame(width: imageSize.width, height: imageSize.height)
                .clipped()
            
            if asset.result.urlReuslt.mediaType == .video {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .shadow(radius: 1)
                    .scaleEffect(2)
                
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "video")
                            .foregroundColor(.white)
                            .shadow(radius: 1)
                            .padding([.leading, .bottom], 5)
                        Spacer()
                        Text(asset.videoDuration)
                            .font(.callout)
                            .foregroundColor(.white)
                            .shadow(radius: 1)
                            .padding([.trailing, .bottom], 5)
                    }
                }
            }
        }
    }
}
