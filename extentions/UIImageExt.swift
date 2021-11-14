//
//  UIImageExt.swift
//  PhotoComposer
//
//  Created by Joseph Buckshin on 10/9/18.
//  Copyright © 2018 Joseph Buckshin. All rights reserved.
//

import UIKit

extension UIImage {

    func cropped(boundingBox: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: boundingBox) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        var newImage: UIImage?
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(cgImage, in: newRect)
            if let img = context.makeImage() {
                newImage = UIImage(cgImage: img)
            }
            UIGraphicsEndImageContext()
        }
        return newImage
    }
    
    func resize(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    class func resize(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func scaleUIImageToSize(size: CGSize) -> UIImage? {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }
    
    func scaleUIImageToSize(size: CGSize, usingScale scale: CGFloat) -> UIImage? {
        let hasAlpha = true
        //let scale: CGFloat = 0.0 // Automatically use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }
    
    class func scale(image: UIImage, by scale: CGFloat) -> UIImage? {
        let size = image.size
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIImage.resize(image: image, targetSize: scaledSize)
    }
    
    func image(byDrawingImage image: UIImage, inRect rect: CGRect) -> UIImage! {
        
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image.draw(in: rect)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    func imageInterp(byDrawingImage image: UIImage, fromRect rectFrom: CGRect, inRect rectTo: CGRect) -> UIImage! {

        UIGraphicsBeginImageContext(size)
        
        // start point, end point
        // figure out points on the way
        
        let xDist:CGFloat = (rectTo.origin.x - rectFrom.origin.x); //[2]
        let yDist:CGFloat = (rectTo.origin.y - rectFrom.origin.y); //[3]
        let distance:Float = Float(sqrt((xDist * xDist) + (yDist * yDist)));
        var result:UIImage = UIImage(); // dummy instance
        
        // draw once
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let step:Float = 5.0
        if distance > 0.0 {
            for i in stride(from: 0.0, to: distance, by: step) {
                
                // neglecting direction?
                let xDistance = rectTo.origin.x - rectFrom.origin.x;
                let yDistance = rectTo.origin.y - rectFrom.origin.y;
                
                // good.
                let tX = rectFrom.origin.x +  ( CGFloat(i) * (xDistance / CGFloat(distance)));
                let tY = rectFrom.origin.y +  ( CGFloat(i) * (yDistance / CGFloat(distance)));
                
                let newRect = CGRect(x: tX, y: tY, width: rectTo.width, height: rectTo.height);
                image.draw(in: newRect)
                result = UIGraphicsGetImageFromCurrentImageContext()!
            }
        } else {
            // no loop, distance <= 0
            image.draw(in: rectTo)
            result = UIGraphicsGetImageFromCurrentImageContext()!;
        }
        
        UIGraphicsEndImageContext()
        return result
    }
    
    
    func fixOrientation() -> UIImage {
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }

        var transform = CGAffineTransform.identity

        switch self.imageOrientation {
            case .down, .downMirrored:
                transform = transform.translatedBy(x: self.size.width, y: self.size.height)
                transform = transform.rotated(by: CGFloat(Float.pi));

            case .left, .leftMirrored:
                transform = transform.translatedBy(x: self.size.width, y: 0);
                transform = transform.rotated(by: CGFloat(Float.pi));

            case .right, .rightMirrored:
                transform = transform.translatedBy(x: 0, y: self.size.height);
                transform = transform.rotated(by: CGFloat(-Float.pi));

            case .up, .upMirrored:
                break
            default:
                break
        }
        

        switch self.imageOrientation {

            case .up, .downMirrored:
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)

            case .leftMirrored, .rightMirrored:
                transform = transform.translatedBy(x: self.size.height, y: 0)
                transform = transform.scaledBy(x: -1, y: 1);

            default:
                break;
        }

        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        if let ctx = CGContext(
            data: nil,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: self.cgImage!.bitsPerComponent,
            bytesPerRow: 0,
            space: self.cgImage!.colorSpace!,
            bitmapInfo: UInt32(self.cgImage!.bitmapInfo.rawValue)
            )
        {

            ctx.concatenate(transform);

            switch self.imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                // Grr...
                
                ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
                //CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.height,self.size.width), self.cgImage);

            default:
                ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
                //CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.width,self.size.height), self.cgImage);
                break;
            }

            // And now we just create a new UIImage from the drawing context
            let cgimg1 = ctx.makeImage()

            let img = UIImage(cgImage: cgimg1!)

            return img;
        } else {
            print("ctx failed")
        }
        return self
    }
    
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect:CGRect = CGRect(x: 0, y: 0, width: pixelBufferWidth, height: pixelBufferHeight)
        let ciContext = CIContext.init()
        guard let cgImage = ciContext.createCGImage(ciImage, from: imageRect) else {
            return nil
        }
        print("pixelBuffer dim: W: \(cgImage.width) H: \(cgImage.height)")
        self.init(cgImage: cgImage)
    }

    func adjustedCIImage(targetSize: CGSize) -> CIImage? {
        guard let cgImage = cgImage else { fatalError() }
        
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        
        // Video preview is running at 1280x720. Downscale background to same resolution
        let videoWidth = Int(targetSize.width)
        let videoHeight = Int(targetSize.height)
        
        let scaleX = CGFloat(imageWidth) / CGFloat(videoWidth)
        let scaleY = CGFloat(imageHeight) / CGFloat(videoHeight)
        
        let scale = min(scaleX, scaleY)
        
        // crop the image to have the right aspect ratio
        let cropSize = CGSize(width: CGFloat(videoWidth) * scale, height: CGFloat(videoHeight) * scale)
        let croppedImage = cgImage.cropping(to: CGRect(origin: CGPoint(
            x: (imageWidth - Int(cropSize.width)) / 2,
            y: (imageHeight - Int(cropSize.height)) / 2), size: cropSize))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: videoWidth,
                                      height: videoHeight,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                                        print("error")
                                        return nil
        }
        
        let bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: videoWidth, height: videoHeight))
        context.clear(bounds)
        
        context.draw(croppedImage!, in: bounds)
        
        guard let scaledImage = context.makeImage() else {
            print("failed")
            return nil
        }
        
        return CIImage(cgImage: scaledImage)
    }
}
