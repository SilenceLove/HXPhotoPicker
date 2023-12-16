//
//  ContentView.swift
//  SwiftUIExample
//
//  Created by Silence on 2023/9/8.
//  Copyright © 2023 洪欣. All rights reserved.
//

import SwiftUI
import UIKit
import HXPhotoPicker

@available(iOS 14.0, *)
struct ContentView: View {
    @State var photoAssets: [PhotoAsset]
    @State var assets: [Asset]
    @State var assetResults: [AssetResult] = []
    @State var transitionTypes: [PhotoBrowser.TransitionType] = []
    
    init(photoAssets: [PhotoAsset], assets: [Asset]) {
        self.photoAssets = photoAssets
        self.assets = assets
        var transitionTypes: [PhotoBrowser.TransitionType] = []
        for _ in assets {
            transitionTypes.append(.end)
        }
        self.transitionTypes = transitionTypes
        
        itemSpacing = 12
        itemCount = UIDevice.isPad ? 5 : 3
        let itemWidth = (UIDevice.screenSize.width - (itemSpacing * 2 + itemSpacing * (itemCount - 1))) / itemCount
        itemSize = CGSize(width: itemWidth, height: itemWidth)
        var items: [GridItem] = []
        let count = Int(itemCount)
        for _ in 0..<count {
            items.append(.init(.fixed(itemSize.width), spacing: itemSpacing))
        }
        gridItemLayout = items
    }
    
    @State private var config: PickerConfiguration = {
        var config = PickerConfiguration.default
        config.modalPresentationStyle = .fullScreen
        config.photoList.bottomView.disableFinishButtonWhenNotSelected = false
        return config
    }()
    @State private var isShowingSetting = false
    @State private var isShowingPicker = false
    @State private var isShowingDelete = false
    @State private var pageIndex: Int = 0
    @State private var draggedItem: Int = 0
    private let itemSize: CGSize
    private let itemCount: CGFloat
    private let itemSpacing: CGFloat
    private let gridItemLayout: [GridItem]
    
    private let framesModel: FramesModel = .init()
    
    var body: some View {
        NavigationView {
            GeometryReader { scrollProxy in
                ScrollView {
                    LazyVGrid(columns: gridItemLayout, spacing: itemSpacing) {
                        ForEach(Array(assets.enumerated()), id: \.element.id) { (index, asset) in
                            ZStack {
                                GeometryReader { proxy in
                                    let frame = proxy.frame(in: .named("ScrollView"))
                                    Button {
                                        let scrollTop = scrollProxy.frame(in: .global).minY
                                        PhotoBrowser(
                                            pageIndex: index,
                                            rowCount: itemCount,
                                            photoAssets: $photoAssets,
                                            assets: $assets,
                                            transitionTypes: $transitionTypes
                                        ).show(
                                            asset.result.image,
                                            itemSize: itemSize
                                        ) {
                                            let frame = self.framesModel.frames[$0]
                                            return .init(x: frame.minX, y: frame.minY + scrollTop)
                                        }
                                    } label: {
                                        photoView(asset, index: index, frame: frame)
                                    }
                                }
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button {
                                            pageIndex = index
                                            isShowingDelete.toggle()
                                        } label: {
                                            Image(systemName: "delete.backward.fill")
                                                .foregroundColor(.white)
                                                .shadow(radius: 1)
                                                .scaleEffect(1.2, anchor: .topTrailing)
                                                .padding([.top, .trailing], 1)
                                        }
                                        .alert(isPresented: $isShowingDelete) {
                                            Alert(
                                                title: Text("是否删除"),
                                                primaryButton: .cancel(),
                                                secondaryButton: .default(Text("确定"), action: {
                                                    withAnimation {
                                                        photoAssets.remove(at: pageIndex)
                                                        assets.remove(at: pageIndex)
                                                    }
                                            }))
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            .frame(width: itemSize.width, height: itemSize.height)
                            .cornerRadius(5)
                            .opacity(transitionTypes[index].opacity)
                        }
                        .padding([.leading, .trailing], itemSpacing)
                        
                        if config.maximumSelectedCount == 0 ||
                            assets.count < config.maximumSelectedCount {
                            Button {
                                isShowingPicker.toggle()
                            } label: {
                                ZStack {
                                    Color(hex: 0xEEEEEE)
                                        .frame(width: itemSize.width, height: itemSize.height)
                                        .cornerRadius(5)
                                    Image(systemName: "plus")
                                        .foregroundColor(Color(hex: 0x999999))
                                        .scaleEffect(2)
                                }
                                .padding([.leading, .trailing], itemSpacing)
                            }
                        }
                    }
                    .navigationTitle("SwiftUI Example")
                    .navigationBarItems(trailing: Button(action: {
                        isShowingSetting.toggle()
                    }, label: {
                        Text("设置")
                    }))
                    .padding([.leading, .trailing], itemSpacing)
                }
                .coordinateSpace(name: "ScrollView")
                .fullScreenCover(isPresented: $isShowingPicker, content: {
                    PhotoPickerView(config: config, photoAssets: $photoAssets, assetResults: $assetResults)
                        .ignoresSafeArea()
                })
    //                .sheet(isPresented: $isShowingPicker, content: {
    //                    PhotoPickerView(config: config, photoAssets: $photoAssets, assetResults: $assetResults)
    //                        .ignoresSafeArea()
    //                })
                .sheet(isPresented: $isShowingSetting, content: {
                    ConfigView(config: $config)
                        .ignoresSafeArea()
                })
            }
        }
        .onChange(of: photoAssets, perform: { newValue in
            var transitionTypes: [PhotoBrowser.TransitionType] = []
            for _ in newValue {
                transitionTypes.append(.end)
            }
            self.transitionTypes = transitionTypes
            var assets: [Asset] = []
            var frames: [CGRect] = []
            for (index, photoAsset) in newValue.enumerated() {
                assets.append(.init(
                    result: assetResults[index],
                    videoDuration: photoAsset.videoTime ?? "",
                    photoAsset: photoAsset
                ))
                frames.append(.zero)
            }
            framesModel.frames = frames
            self.assets = assets
        })
        .navigationViewStyle(StackNavigationViewStyle())
    }
    func photoView(_ asset: Asset, index: Int, frame: CGRect) -> AnyView {
        framesModel.frames[index] = frame
        return AnyView(PhotoView(asset: asset)
            .frame(width: itemSize.width, height: itemSize.height))
    }
}

@available(iOS 14.0, *)
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

class FramesModel {
    var frames: [CGRect] = []
}
