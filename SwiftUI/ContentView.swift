//
//  ContentView.swift
//  SwiftUIExample
//
//  Created by Silence on 2023/9/8.
//  Copyright © 2023 洪欣. All rights reserved.
//

import SwiftUI
import HXPhotoPicker

struct ContentView: View {
    @State var config: PickerConfiguration = {
        var config = PickerConfiguration.default
        config.photoList.bottomView.disableFinishButtonWhenNotSelected = false
        return config
    }()
    @State private var isShowingSetting = false
    @State private var isShowingPicker = false
    @State private var isShowingBrowser = false
    @State private var isShowingDelete = false
    @State private var pageIndex: Int = 0
    @State var photoAssets: [PhotoAsset]
    @State var assets: [Asset]
    @State private var draggedItem: Int = 0
    
    var gridItemLayout = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: gridItemLayout, spacing: 12) {
                        let itemWidth = (geometry.size.width - 48) / 3
                        ForEach(0..<assets.count, id:\.self) { index in
                            let asset = assets[index]
                            Button {
                                pageIndex = index
                                isShowingBrowser.toggle()
                            } label: {
                                ZStack {
                                    PhotoView(asset: asset)
                                        .frame(width: itemWidth, height: itemWidth)
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
                                .onDrop(of: ["\(index)"], delegate: DragDropDelegate(fromIndex: $draggedItem, toIndex: index, itemSize: .init(width: itemWidth, height: itemWidth), photoAssets: $photoAssets, assets: $assets))
                            }
                        }
                        .padding([.leading, .trailing], 12)
                        
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
                                .padding([.leading, .trailing], 12)
                            }
                        }
                    }
                    .navigationTitle("SwiftUI Example")
                    .navigationBarItems(trailing: Button(action: {
                        isShowingSetting.toggle()
                    }, label: {
                        Text("设置")
                    }))
                    .padding([.leading, .trailing], 12)
                }
                .sheet(isPresented: $isShowingBrowser, content: {
                    PhotoBrowser(pageIndex: pageIndex, photoAssets: $photoAssets, assets: $assets)
                        .ignoresSafeArea()
                })
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(photoAssets: [], assets: [])
    }
}

struct DragDropDelegate: DropDelegate {
    @Binding var fromIndex: Int
    let toIndex: Int
    let itemSize: CGSize
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
