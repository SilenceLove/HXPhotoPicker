/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Metal preview view.
*/

import CoreMedia
import Metal
import MetalKit

class PreviewMetalView: MTKView {
    
    enum Rotation: Int {
        case rotate0Degrees
        case rotate90Degrees
        case rotate180Degrees
        case rotate270Degrees
    }
    
    var mirroring = false {
        didSet {
            syncQueue.sync {
                internalMirroring = mirroring
            }
        }
    }
    
    private var internalMirroring: Bool = false
    
    var rotation: Rotation = .rotate0Degrees {
        didSet {
            syncQueue.sync {
                internalRotation = rotation
            }
        }
    }
    
    private var internalRotation: Rotation = .rotate0Degrees
    
    var pixelBuffer: CVPixelBuffer? {
        didSet {
            if pixelBuffer == nil {
                isPreviewing = false
            }
            syncQueue.sync {
                internalPixelBuffer = pixelBuffer
            }
        }
    }
    
    var isPreviewing: Bool = false
    
    var didPreviewing: ((Bool) -> Void)?
    
    private var internalPixelBuffer: CVPixelBuffer?
    
    private let syncQueue = DispatchQueue(
        label: "com.silence.previewViewSyncQueue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    private var textureCache: CVMetalTextureCache?
    
    private var textureWidth: Int = 0
    
    private var textureHeight: Int = 0
    
    private var textureMirroring = false
    
    private var textureRotation: Rotation = .rotate0Degrees
    
    private var sampler: MTLSamplerState!
    
    private var renderPipelineState: MTLRenderPipelineState!
    
    private var commandQueue: MTLCommandQueue?
    
    private var vertexCoordBuffer: MTLBuffer!
    
    private var textCoordBuffer: MTLBuffer!
    
    private var internalBounds: CGRect!
    
    private var textureTranform: CGAffineTransform?
    
    func texturePointForView(point: CGPoint) -> CGPoint? {
        var result: CGPoint?
        guard let transform = textureTranform else {
            return result
        }
        let transformPoint = point.applying(transform)
        
        if CGRect(origin: .zero, size: CGSize(width: textureWidth, height: textureHeight)).contains(transformPoint) {
            result = transformPoint
        } else {
            print("Invalid point \(point) result point \(transformPoint)")
        }
        
        return result
    }
    
    func viewPointForTexture(point: CGPoint) -> CGPoint? {
        var result: CGPoint?
        guard let transform = textureTranform?.inverted() else {
            return result
        }
        let transformPoint = point.applying(transform)
        
        if internalBounds.contains(transformPoint) {
            result = transformPoint
        } else {
            print("Invalid point \(point) result point \(transformPoint)")
        }
        
        return result
    }
    
    func flushTextureCache() {
        textureCache = nil
    }
    
    private func setupTransform(width: Int, height: Int, mirroring: Bool, rotation: Rotation) {
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0
        var resizeAspect: Float = 1.0
        
        internalBounds = self.bounds
        textureWidth = width
        textureHeight = height
        textureMirroring = mirroring
        textureRotation = rotation
        
        if textureWidth > 0 && textureHeight > 0 {
            switch textureRotation {
            case .rotate0Degrees, .rotate180Degrees:
                scaleX = Float(internalBounds.width / CGFloat(textureWidth))
                scaleY = Float(internalBounds.height / CGFloat(textureHeight))
                
            case .rotate90Degrees, .rotate270Degrees:
                scaleX = Float(internalBounds.width / CGFloat(textureHeight))
                scaleY = Float(internalBounds.height / CGFloat(textureWidth))
            }
        }
        // Resize aspect ratio.
        resizeAspect = min(scaleX, scaleY)
        if scaleX < scaleY {
            scaleY = scaleX / scaleY
            scaleX = 1.0
        } else {
            scaleX = scaleY / scaleX
            scaleY = 1.0
        }
        
        if textureMirroring {
            scaleX *= -1.0
        }
        
        // Vertex coordinate takes the gravity into account.
        let vertexData: [Float] = [
            -scaleX, -scaleY, 0.0, 1.0,
            scaleX, -scaleY, 0.0, 1.0,
            -scaleX, scaleY, 0.0, 1.0,
            scaleX, scaleY, 0.0, 1.0
        ]
        vertexCoordBuffer = device!.makeBuffer(
            bytes: vertexData,
            length: vertexData.count * MemoryLayout<Float>.size,
            options: []
        )
        
        // Texture coordinate takes the rotation into account.
        var textData: [Float]
        switch textureRotation {
        case .rotate0Degrees:
            textData = [
                0.0, 1.0,
                1.0, 1.0,
                0.0, 0.0,
                1.0, 0.0
            ]
            
        case .rotate180Degrees:
            textData = [
                1.0, 0.0,
                0.0, 0.0,
                1.0, 1.0,
                0.0, 1.0
            ]
            
        case .rotate90Degrees:
            textData = [
                1.0, 1.0,
                1.0, 0.0,
                0.0, 1.0,
                0.0, 0.0
            ]
            
        case .rotate270Degrees:
            textData = [
                0.0, 0.0,
                0.0, 1.0,
                1.0, 0.0,
                1.0, 1.0
            ]
        }
        textCoordBuffer = device?.makeBuffer(
            bytes: textData,
            length: textData.count * MemoryLayout<Float>.size,
            options: []
        )
        
        // Calculate the transform from texture coordinates to view coordinates
        var transform = CGAffineTransform.identity
        if textureMirroring {
            transform = transform.concatenating(CGAffineTransform(scaleX: -1, y: 1))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureWidth), y: 0))
        }
        
        switch textureRotation {
        case .rotate0Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(0)))
            
        case .rotate180Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(Double.pi)))
            transform = transform.concatenating(
                CGAffineTransform(
                    translationX: CGFloat(textureWidth),
                    y: CGFloat(textureHeight)
                )
            )
            
        case .rotate90Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(Double.pi) / 2))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureHeight), y: 0))
            
        case .rotate270Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: 3 * CGFloat(Double.pi) / 2))
            transform = transform.concatenating(CGAffineTransform(translationX: 0, y: CGFloat(textureWidth)))
        }
        
        transform = transform.concatenating(CGAffineTransform(scaleX: CGFloat(resizeAspect), y: CGFloat(resizeAspect)))
        let tranformRect = CGRect(
            origin: .zero,
            size: CGSize(width: textureWidth, height: textureHeight)
        ).applying(transform)
        let xShift = (internalBounds.size.width - tranformRect.size.width) / 2
        let yShift = (internalBounds.size.height - tranformRect.size.height) / 2
        transform = transform.concatenating(CGAffineTransform(translationX: xShift, y: yShift))
        textureTranform = transform.inverted()
    }
    init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        configureMetal()
        createTextureCache()
        colorPixelFormat = .bgra8Unorm
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    } 
    func configureMetal() {
        guard let device = device else {
            return
        }
        let defaultLibrary: MTLLibrary
        PhotoManager.shared.createBundle()
        if let bundle = PhotoManager.shared.bundle,
           let path = bundle.path(forResource: "metal/default", ofType: "metallib"),
           let library = try? device.makeLibrary(filepath: path) {
            defaultLibrary = library
        }else {
            do {
                defaultLibrary = try device.makeDefaultLibrary(bundle: .main)
            } catch {
                return
            }
        }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexPassThrough")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentPassThrough")
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create preview Metal view pipeline state. (\(error))")
        }
        preferredFramesPerSecond = 30
        commandQueue = device.makeCommandQueue()
    }
    
    func createTextureCache() {
        guard let device = device else { return }
        var newTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &newTextureCache) == kCVReturnSuccess {
            textureCache = newTextureCache
        }
    }
    
    /// - Tag: DrawMetalTexture
    override func draw(_ rect: CGRect) {
        var pixelBuffer: CVPixelBuffer?
        var mirroring = false
        var rotation: Rotation = .rotate0Degrees
        
        syncQueue.sync {
            pixelBuffer = internalPixelBuffer
            mirroring = internalMirroring
            rotation = internalRotation
        }
        
        guard let drawable = currentDrawable,
            let currentRenderPassDescriptor = currentRenderPassDescriptor,
            let previewPixelBuffer = pixelBuffer else {
                return
        }
        
        // Create a Metal texture from the image buffer.
        let width = CVPixelBufferGetWidth(previewPixelBuffer)
        let height = CVPixelBufferGetHeight(previewPixelBuffer)
        
        if textureCache == nil {
            createTextureCache()
        }
        guard let textureCache = textureCache else { return }
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            previewPixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTextureOut
        )
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to create preview texture")
            CVMetalTextureCacheFlush(textureCache, 0)
            return
        }
        
        if texture.width != textureWidth ||
            texture.height != textureHeight ||
            self.bounds != internalBounds ||
            mirroring != textureMirroring ||
            rotation != textureRotation {
            setupTransform(
                width: texture.width,
                height: texture.height,
                mirroring: mirroring,
                rotation: rotation
            )
        }
        
        // Set up command buffer and encoder
        guard let commandQueue = commandQueue else {
            print("Failed to create Metal command queue")
            CVMetalTextureCacheFlush(textureCache, 0)
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("Failed to create Metal command buffer")
            CVMetalTextureCacheFlush(textureCache, 0)
            return
        }
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: currentRenderPassDescriptor
        ) else {
            print("Failed to create Metal command encoder")
            CVMetalTextureCacheFlush(textureCache, 0)
            return
        }
        
        commandEncoder.label = "Preview display"
        commandEncoder.setRenderPipelineState(renderPipelineState!)
        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textCoordBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()
        
        // Draw to the screen.
        commandBuffer.present(drawable)
        commandBuffer.commit()
        DispatchQueue.main.async {
            self.didPreviewing?(!self.isPreviewing)
            self.isPreviewing = true
        }
    }
}
