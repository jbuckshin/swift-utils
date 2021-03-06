


import CoreImage

extension CIImage {
    func resizeToSameSize(as anotherImage: CIImage) -> CIImage {
        let size1 = extent.size
        let size2 = anotherImage.extent.size
        let transform = CGAffineTransform(scaleX: size2.width / size1.width, y: size2.height / size1.height)
        return transformed(by: transform)
    }

    func createCGImage() -> CGImage {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(self, from: extent) else { fatalError() }
        return cgImage
    }
}
