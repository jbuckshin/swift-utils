//
//  TrigHelper.swift
//  Blend
//
//  Created by Joe Buckshin on 10/17/21.
//  Copyright © 2021 Joseph Buckshin. All rights reserved.
//

import UIKit

func sin(degrees: Double) -> Double {
    return __sinpi(degrees/180.0)
}

func sin(degrees: Float) -> Float {
    return __sinpif(degrees/180.0)
}

func sin(degrees: CGFloat) -> CGFloat {
    return CGFloat(sin(degrees: degrees.native))
}

func cos(degrees: Double) -> Double {
    return __cospi(degrees/180.0)
}

func cos(degrees: Float) -> Float {
    return __cospif(degrees/180.0)
}

func cos(degrees: CGFloat) -> CGFloat {
    return CGFloat(cos(degrees: degrees.native))
}
