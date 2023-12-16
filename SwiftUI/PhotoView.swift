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
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(uiImage: asset.result.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                
                if asset.result.urlReuslt.mediaType == .video {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                        .scaleEffect(2)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        if asset.photoAsset.mediaSubType.isVideo {
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
                        }else if asset.photoAsset.isGifAsset {
                            Spacer()
                            Text("GIF")
                                .font(.callout)
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                                .padding([.trailing, .bottom], 5)
                        }else if asset.photoAsset.mediaSubType.isLivePhoto {
                            Spacer()
                            Text("LivePhoto")
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
}
