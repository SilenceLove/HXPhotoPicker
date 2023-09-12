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
    
    init(photoAssets: [PhotoAsset], assets: [Asset]) {
        self.photoAssets = photoAssets
        self.assets = assets
    }
    
    @State private var config: PickerConfiguration = {
        var config = PickerConfiguration.default
        config.photoList.bottomView.disableFinishButtonWhenNotSelected = false
        return config
    }()
    @State private var isShowingSetting = false
    @State private var isShowingPicker = false
    @State private var isShowingDelete = false
    @State private var pageIndex: Int = 0
    @State private var draggedItem: Int = 0
    
    private var itemCount: CGFloat = UIDevice.isPad ? 5 : 3
    private var itemSpacing: CGFloat = 12
    private var gridItemLayout = {
        var items: [GridItem] = []
        let count = UIDevice.isPad ? 5 : 3
        for _ in 0..<count {
            items.append(.init(.flexible(), spacing: 12))
        }
        return items
    }()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVGrid(columns: gridItemLayout, spacing: itemSpacing) {
                        let itemWidth = (geometry.size.width - (itemSpacing * 2 + itemSpacing * (itemCount - 1))) / itemCount
                        let itemSize = CGSize(width: itemWidth, height: itemWidth)
                        ForEach(0..<assets.count, id:\.self) { index in
                            let asset = assets[index]
                            ZStack {
                                PhotoView(asset: asset, imageSize: itemSize)
                                    .onTapGesture {
                                        PhotoBrowser(
                                            pageIndex: index,
                                            photoAssets: $photoAssets,
                                            assets: $assets
                                        ).show(
                                            asset.result.image,
                                            topMargin: geometry.frame(in: .global).minY,
                                            itemSize: itemSize
                                        )
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
                            .cornerRadius(5)
                            .onDrag {
                                draggedItem = index
                                return NSItemProvider(object: "\(index)" as NSString)
                            }
                            .onDrop(
                                of: ["\(index)"],
                                delegate: DragDropDelegate(
                                    fromIndex: $draggedItem,
                                    toIndex: index,
                                    photoAssets: $photoAssets,
                                    assets: $assets
                                )
                            )
                        }
                        .padding([.leading, .trailing], itemSpacing)
                        
                        if config.maximumSelectedCount == 0 ||
                            assets.count < config.maximumSelectedCount {
                            Button {
                                isShowingPicker.toggle()
                            } label: {
                                ZStack {
                                    Color(hex: 0xEEEEEE)
                                        .frame(width: itemWidth, height: itemWidth)
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
                .sheet(isPresented: $isShowingPicker, content: {
                    PhotoPickerView(config: config, photoAssets: $photoAssets, assets: $assets)
                        .ignoresSafeArea()
                })
                .sheet(isPresented: $isShowingSetting, content: {
                    ConfigView(config: $config)
                        .ignoresSafeArea()
                })
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

@available(iOS 14.0, *)
struct DragDropDelegate: DropDelegate {
    @Binding var fromIndex: Int
    let toIndex: Int
    @Binding var photoAssets: [PhotoAsset]
    @Binding var assets: [Asset]
    
    func dropEntered(info: DropInfo) {
        if fromIndex != toIndex {
            withAnimation {
                photoAssets.swapAt(fromIndex, toIndex)
                assets.swapAt(fromIndex, toIndex)
            }
            fromIndex = toIndex
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        .init(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        true
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
