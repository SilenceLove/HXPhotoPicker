//
//  EditorMaskListProtocol.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/3/16.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public protocol EditorMaskListDelete: AnyObject {
    func editorMaskList(
        _ chartletList: EditorMaskListProtocol,
        didSelectedWith image: UIImage
    )
}

public protocol EditorMaskListProtocol: UIViewController {
    var delegate: EditorMaskListDelete? { get set }
    init(config: EditorConfiguration)
}
