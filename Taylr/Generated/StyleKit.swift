//
//  StyleKit.swift
//  Taylr
//
//  Created by Tony Xiao on 7/21/15.
//  Copyright (c) 2015 S10 Inc.. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//



import UIKit

public class StyleKit : NSObject {

    //// Cache

    private struct Cache {
        static var brandPurple: UIColor = UIColor(red: 0.290, green: 0.078, blue: 0.549, alpha: 1.000)
        static var teal: UIColor = UIColor(red: 0.137, green: 0.588, blue: 0.580, alpha: 1.000)
        static var navy: UIColor = UIColor(red: 0.051, green: 0.392, blue: 0.537, alpha: 1.000)
        static var textWhite: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        static var backgroundWhite: UIColor = UIColor(red: 0.933, green: 0.941, blue: 0.949, alpha: 1.000)
        static var waterBlue: UIColor = UIColor(red: 0.055, green: 0.894, blue: 0.941, alpha: 1.000)
        static var waterAlt: UIColor = UIColor(red: 0.263, green: 0.871, blue: 0.863, alpha: 1.000)
        static var gradientWaterColor: UIColor = UIColor(red: 0.549, green: 0.976, blue: 1.000, alpha: 1.000)
        static var sand: UIColor = UIColor(red: 0.596, green: 0.588, blue: 0.510, alpha: 1.000)
        static var gradientSandColor: UIColor = UIColor(red: 0.882, green: 0.871, blue: 0.788, alpha: 1.000)
        static var gradientSandColor2: UIColor = UIColor(red: 0.941, green: 0.980, blue: 0.969, alpha: 1.000)
        static var pureWhite: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        static var waterTop: UIColor = UIColor(red: 0.773, green: 1.000, blue: 0.997, alpha: 1.000)
        static var waterBottom: UIColor = UIColor(red: 0.055, green: 0.894, blue: 0.941, alpha: 1.000)
        static var navyLight: UIColor = StyleKit.navy.colorWithAlpha(0.22)
        static var tealLight: UIColor = StyleKit.teal.colorWithHighlight(0.77)
        static var tealDark: UIColor = StyleKit.teal.colorWithShadow(0.45)
        static var navy35: UIColor = StyleKit.navy.colorWithAlpha(0.35)
        static var gradientWater: CGGradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [StyleKit.gradientWaterColor.CGColor, StyleKit.waterBlue.CGColor, StyleKit.waterAlt.CGColor], [0, 0.19, 1])
        static var gradientSand: CGGradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [StyleKit.gradientSandColor.CGColor, StyleKit.gradientSandColor2.CGColor], [0, 1])
        static var candidateShadow: NSShadow = NSShadow(color: UIColor.blackColor().colorWithAlphaComponent(0.1), offset: CGSizeMake(0.1, -1.1), blurRadius: 3)
    }

    //// Colors

    public class var brandPurple: UIColor { return Cache.brandPurple }
    public class var teal: UIColor { return Cache.teal }
    public class var navy: UIColor { return Cache.navy }
    public class var textWhite: UIColor { return Cache.textWhite }
    public class var backgroundWhite: UIColor { return Cache.backgroundWhite }
    public class var waterBlue: UIColor { return Cache.waterBlue }
    public class var waterAlt: UIColor { return Cache.waterAlt }
    public class var gradientWaterColor: UIColor { return Cache.gradientWaterColor }
    public class var sand: UIColor { return Cache.sand }
    public class var gradientSandColor: UIColor { return Cache.gradientSandColor }
    public class var gradientSandColor2: UIColor { return Cache.gradientSandColor2 }
    public class var pureWhite: UIColor { return Cache.pureWhite }
    public class var waterTop: UIColor { return Cache.waterTop }
    public class var waterBottom: UIColor { return Cache.waterBottom }
    public class var navyLight: UIColor { return Cache.navyLight }
    public class var tealLight: UIColor { return Cache.tealLight }
    public class var tealDark: UIColor { return Cache.tealDark }
    public class var navy35: UIColor { return Cache.navy35 }

    //// Gradients

    public class var gradientWater: CGGradient { return Cache.gradientWater }
    public class var gradientSand: CGGradient { return Cache.gradientSand }

    //// Shadows

    public class var candidateShadow: NSShadow { return Cache.candidateShadow }

}



extension UIColor {
    func colorWithHue(newHue: CGFloat) -> UIColor {
        var saturation: CGFloat = 1.0, brightness: CGFloat = 1.0, alpha: CGFloat = 1.0
        self.getHue(nil, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return UIColor(hue: newHue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    func colorWithSaturation(newSaturation: CGFloat) -> UIColor {
        var hue: CGFloat = 1.0, brightness: CGFloat = 1.0, alpha: CGFloat = 1.0
        self.getHue(&hue, saturation: nil, brightness: &brightness, alpha: &alpha)
        return UIColor(hue: hue, saturation: newSaturation, brightness: brightness, alpha: alpha)
    }
    func colorWithBrightness(newBrightness: CGFloat) -> UIColor {
        var hue: CGFloat = 1.0, saturation: CGFloat = 1.0, alpha: CGFloat = 1.0
        self.getHue(&hue, saturation: &saturation, brightness: nil, alpha: &alpha)
        return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
    func colorWithAlpha(newAlpha: CGFloat) -> UIColor {
        var hue: CGFloat = 1.0, saturation: CGFloat = 1.0, brightness: CGFloat = 1.0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: newAlpha)
    }
    func colorWithHighlight(highlight: CGFloat) -> UIColor {
        var red: CGFloat = 1.0, green: CGFloat = 1.0, blue: CGFloat = 1.0, alpha: CGFloat = 1.0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: red * (1-highlight) + highlight, green: green * (1-highlight) + highlight, blue: blue * (1-highlight) + highlight, alpha: alpha * (1-highlight) + highlight)
    }
    func colorWithShadow(shadow: CGFloat) -> UIColor {
        var red: CGFloat = 1.0, green: CGFloat = 1.0, blue: CGFloat = 1.0, alpha: CGFloat = 1.0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: red * (1-shadow), green: green * (1-shadow), blue: blue * (1-shadow), alpha: alpha * (1-shadow) + shadow)
    }
}



extension NSShadow {
    convenience init(color: AnyObject!, offset: CGSize, blurRadius: CGFloat) {
        self.init()
        self.shadowColor = color
        self.shadowOffset = offset
        self.shadowBlurRadius = blurRadius
    }
}

@objc protocol StyleKitSettableImage {
    func setImage(image: UIImage!)
}

@objc protocol StyleKitSettableSelectedImage {
    func setSelectedImage(image: UIImage!)
}
