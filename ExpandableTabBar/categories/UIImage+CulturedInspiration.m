//
//  UIImage+CulturedInspiration.m
//  concierge
//
//  Created by Brendan Dixon on 2/20/11.
//  Copyright 2011 cultured inspiration. All rights reserved.
//

#import "UIImage+CulturedInspiration.h"


@implementation UIImage(CulturedInspiration)

#pragma mark - Class Methods

//-----------------------------------------------------------------------------------------------------------
// Create an image of the requested color and size
//
+ (UIImage*)imageFromColor:(UIColor*)color withSize:(CGSize)size {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  
  [[UIColor lightGrayColor] set];
  UIRectFill(CGRectMake(0, 0, size.width, size.height));
  
  UIImage* imageResult = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  
  return imageResult;
}

//-----------------------------------------------------------------------------------------------------------
// Create an image of the requested size with the passed image centered
//
+ (UIImage*)imageFromImage:(UIImage*)image withSize:(CGSize)size {
  
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  
  [image drawInRect:CGRectMake((size.width - CGImageGetWidth(image.CGImage)) / 2,
                               (size.height - CGImageGetHeight(image.CGImage)) / 2,
                               CGImageGetWidth(image.CGImage),
                               CGImageGetHeight(image.CGImage))];
  
  UIImage* imageResult = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  
  return imageResult;
}


#pragma mark - Instance Methods

//-----------------------------------------------------------------------------------------------------------
// Create an alpha mask from the current image
//
- (UIImage*)alphaMask {

  CGImageRef cgImage = self.CGImage;

  // Create a CGContext of an appropriate size
  CGRect rect = CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
  CGContextRef context = CGBitmapContextCreate(NULL, rect.size.width, rect.size.height, 8, 0, CGImageGetColorSpace(cgImage), kCGImageAlphaPremultipliedLast);

  // Fill the context with 100% white (that is, clip everything)
  CGContextSetRGBFillColor(context, 1, 1, 1, 1);
  CGContextFillRect(context, rect);
  
  // Next, use the image as a clipping mask and fill with black
  CGContextClipToMask(context, rect, cgImage);
  CGContextSetRGBFillColor(context, 0, 0, 0, 1);
  CGContextFillRect(context, rect);

  // Finally, create the image mask from the context
  CGImageRef cgImageBlackWhite = CGBitmapContextCreateImage(context);
  CGImageRef cgImageMask = CGImageMaskCreate(CGImageGetWidth(cgImageBlackWhite),
                                             CGImageGetHeight(cgImageBlackWhite),
                                             CGImageGetBitsPerComponent(cgImageBlackWhite),
                                             CGImageGetBitsPerPixel(cgImageBlackWhite),
                                             CGImageGetBytesPerRow(cgImageBlackWhite),
                                             CGImageGetDataProvider(cgImageBlackWhite),
                                             NULL,
                                             YES);

  UIImage* alphaMask = [UIImage imageWithCGImage:cgImageMask scale:self.scale orientation:self.imageOrientation];
  
  CGContextRelease(context);
  CGImageRelease(cgImageBlackWhite);
  CGImageRelease(cgImageMask);
  
  return alphaMask;
}

@end
