//
//  KeyboardButton.swift
//  KeyboardLayoutEngine
//
//  Created by Cem Olcay on 06/05/16.
//  Copyright © 2016 Prototapp. All rights reserved.
//

import UIKit
import Shadow

// MARK: - KeyboardButtonType
public enum KeyboardButtonType {
  case Key(String)
  case Text(String)
  case Image(UIImage?)
}

// MARK: - KeyboardButtonWidth
public enum KeyboardButtonWidth {
  case Dynamic
  case Static(width: CGFloat)
  case Relative(percent: CGFloat)
}

// MARK: - KeyboardButtonStyle
public struct KeyboardButtonStyle {
  public var backgroundColor: UIColor
  public var cornerRadius: CGFloat

  // Border
  public var borderColor: UIColor
  public var borderWidth: CGFloat

  // Shadow
  public var shadow: Shadow?

  // Text
  public var textColor: UIColor
  public var font: UIFont
  public var textOffsetY: CGFloat

  // Image
  public var imageSize: CGFloat?
  public var tintColor: UIColor

  // KeyPop
  public var keyPopType: KeyPopType?
  public var keyPopWidthMultiplier: CGFloat
  public var keyPopHeightMultiplier: CGFloat
  public var keyPopContainerView: UIView?

  public init(
    backgroundColor: UIColor? = nil,
    cornerRadius: CGFloat? = nil,
    borderColor: UIColor? = nil,
    borderWidth: CGFloat? = nil,
    shadow: Shadow? = nil,
    textColor: UIColor? = nil,
    font: UIFont? = nil,
    textOffsetY: CGFloat? = nil,
    imageSize: CGFloat? = nil,
    tintColor: UIColor = UIColor.blackColor(),
    keyPopType: KeyPopType? = nil,
    keyPopWidthMultiplier: CGFloat? = nil,
    keyPopHeightMultiplier: CGFloat? = nil,
    keyPopContainerView: UIView? = nil) {
    self.backgroundColor = backgroundColor ?? UIColor.whiteColor()
    self.cornerRadius = cornerRadius ?? 5
    self.borderColor = borderColor ?? UIColor.clearColor()
    self.borderWidth = borderWidth ?? 0
    self.shadow = shadow
    self.textColor = textColor ?? UIColor.blackColor()
    self.font = font ?? UIFont.systemFontOfSize(21)
    self.textOffsetY = textOffsetY ?? 0
    self.imageSize = imageSize
    self.tintColor = tintColor
    self.keyPopType = keyPopType
    self.keyPopWidthMultiplier = keyPopWidthMultiplier ?? 1.5
    self.keyPopHeightMultiplier = keyPopHeightMultiplier ?? 1.1
    self.keyPopContainerView = keyPopContainerView
  }
}

// MARK: - KeyboardButton
public var KeyboardButtonPopupViewTag: Int = 101
public var KeyboardButtonMenuViewTag: Int = 102

public class KeyboardButton: UIView {
  public var type: KeyboardButtonType = .Key("") { didSet { reload() } }
  public var widthInRow: KeyboardButtonWidth = .Dynamic { didSet { reload() } }
  public var style: KeyboardButtonStyle! { didSet { reload() } }
  public var keyMenu: KeyMenu?

  public var textLabel: UILabel?
  public var imageView: UIImageView?

  public var identifier: String?
  public var hitRangeInsets: UIEdgeInsets = UIEdgeInsetsZero

  // MARK: Init
  public init(
    type: KeyboardButtonType,
    style: KeyboardButtonStyle,
    width: KeyboardButtonWidth = .Dynamic,
    menu: KeyMenu? = nil,
    identifier: String? = nil) {

    super.init(frame: CGRect.zero)
    self.type = type
    self.style = style
    self.widthInRow = width
    self.identifier = identifier
    reload()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    reload()
  }

  private func reload() {
    userInteractionEnabled = true
    backgroundColor = style.backgroundColor
    layer.cornerRadius = style.cornerRadius

    // border
    layer.borderColor = style.borderColor.CGColor
    layer.borderWidth = style.borderWidth

    // content
    textLabel?.removeFromSuperview()
    textLabel = nil
    imageView?.removeFromSuperview()
    imageView = nil

    switch type {
    case .Key(let text):
      textLabel = UILabel()
      textLabel?.text = text
      textLabel?.textColor = style.textColor
      textLabel?.font = style.font
      textLabel?.textAlignment = .Center
      textLabel?.translatesAutoresizingMaskIntoConstraints = false
      textLabel?.adjustsFontSizeToFitWidth = true
      textLabel?.minimumScaleFactor = 0.5
      addSubview(textLabel!)
    case .Text(let text):
      textLabel = UILabel()
      textLabel?.text = text
      textLabel?.textColor = style.textColor
      textLabel?.font = style.font
      textLabel?.textAlignment = .Center
      textLabel?.translatesAutoresizingMaskIntoConstraints = false
      textLabel?.adjustsFontSizeToFitWidth = true
      textLabel?.minimumScaleFactor = 0.5
      addSubview(textLabel!)
    case .Image(let image):
      imageView = UIImageView(image: image)
      imageView?.contentMode = .ScaleAspectFit
      imageView?.tintColor = style.tintColor
      addSubview(imageView!)
    }
  }

  // MARK: Layout
  public override func layoutSubviews() {
    super.layoutSubviews()
    var padding = CGFloat(0)
    applyShadow(shadow: style.shadow)

    textLabel?.frame = CGRect(
      x: padding,
      y: padding + style.textOffsetY,
      width: frame.size.width - (padding * 2),
      height: frame.size.height - (padding * 2))

    if let imageSize = style.imageSize {
      padding = (min(frame.size.height, frame.size.width) - imageSize) / 2
    }

    imageView?.frame = CGRect(
      x: padding,
      y: padding,
      width: frame.size.width - (padding * 2),
      height: frame.size.height - (padding * 2))
  }

  // MARK: KeyPop
  public func showKeyPop(show show: Bool) {
    if style.keyPopType == nil {
      return
    }

    let view = style.keyPopContainerView ?? self
    if show {
      if view.viewWithTag(KeyboardButtonPopupViewTag) != nil { return }
      let popup = createKeyPop()
      popup.tag = KeyboardButtonPopupViewTag
      popup.frame.origin = convertPoint(popup.frame.origin, toView: view)
      view.addSubview(popup)
    } else {
      if let popup = view.viewWithTag(KeyboardButtonPopupViewTag) {
        popup.removeFromSuperview()
      }
    }
  }

  private func createKeyPop() -> UIView {
    let padding = CGFloat(5)
    let popStyle = KeyPopStyle(
      widthMultiplier: style.keyPopWidthMultiplier,
      heightMultiplier: style.keyPopHeightMultiplier)
    let content = KeyPop(referenceButton: self, style: popStyle)
    let contentWidth = frame.size.width * content.style.widthMultiplier

    var contentX = CGFloat(0)
    var contentRoundCorners = UIRectCorner.AllCorners
    switch style.keyPopType! {
    case .Default:
      contentX = (contentWidth - frame.size.width) / -2.0
    case .Right:
      contentX = frame.size.width - contentWidth
      contentRoundCorners = [.TopLeft, .TopRight, .BottomLeft]
    case .Left:
      contentX = 0
      contentRoundCorners = [.TopLeft, .TopRight, .BottomRight]
    }

    content.frame = CGRect(
      x: contentX,
      y: 0,
      width: contentWidth,
      height: frame.size.height * content.style.heightMultiplier)
    content.frame.origin.y = -(content.frame.size.height + padding)

    let bottomRect = CGRect(
      x: 0,
      y: -padding - 1, // a little hack for filling the gap
      width: frame.size.width,
      height: frame.size.height + padding)

    let path = UIBezierPath(
      roundedRect: content.frame,
      byRoundingCorners: contentRoundCorners,
      cornerRadii: CGSize(
        width: style.cornerRadius * style.keyPopWidthMultiplier,
        height: style.cornerRadius * style.keyPopHeightMultiplier))
    path.appendPath(UIBezierPath(
      roundedRect: bottomRect,
      byRoundingCorners: [.BottomLeft, .BottomRight],
      cornerRadii: CGSize(
        width: style.cornerRadius,
        height: style.cornerRadius)))

    let mask = CAShapeLayer()
    mask.path = path.CGPath
    mask.fillColor = popStyle.backgroundColor.CGColor

    let popup = UIView(
      frame: CGRect(
        x: 0,
        y: 0,
        width: content.frame.size.width,
        height: content.frame.size.height + padding + frame.size.height))
    popup.addSubview(content)
    popup.layer.applyShadow(shadow: popStyle.shadow)
    popup.layer.insertSublayer(mask, atIndex: 0)

    return popup
  }

  // MARK: KeyMenu
  public func showKeyMenu(show show: Bool) {
    if keyMenu == nil {
      return
    }

    let view = style.keyPopContainerView ?? self
    if show {
      if view.viewWithTag(KeyboardButtonMenuViewTag) != nil { return }
      keyMenu?.selectedIndex = -1
      let menu = createKeyMenu()
      menu.tag = KeyboardButtonMenuViewTag
      view.addSubview(menu)
    } else {
      if let menu = view.viewWithTag(KeyboardButtonMenuViewTag) {
        menu.removeFromSuperview()
      }
    }
  }

  private func createKeyMenu() -> UIView {
    guard let content = keyMenu else { return UIView() }
    let padding = CGFloat(5)
    content.frame.origin.y = -(content.frame.size.height + padding)
    content.layer.cornerRadius = style.cornerRadius * style.keyPopWidthMultiplier
    content.clipsToBounds = true

    let bottomRect = CGRect(
      x: 0,
      y: -padding - 1, // a little hack for filling the gap
      width: frame.size.width,
      height: frame.size.height + padding)

    let path = UIBezierPath(
      roundedRect: content.frame,
      byRoundingCorners: [.TopLeft, .TopRight, .BottomRight],
      cornerRadii: CGSize(
        width: style.cornerRadius * style.keyPopWidthMultiplier,
        height: style.cornerRadius * style.keyPopHeightMultiplier))
    path.appendPath(UIBezierPath(
      roundedRect: bottomRect,
      byRoundingCorners: [.BottomLeft, .BottomRight],
      cornerRadii: CGSize(
        width: style.cornerRadius,
        height: style.cornerRadius)))

    let mask = CAShapeLayer()
    mask.path = path.CGPath
    mask.fillColor = content.style.backgroundColor.CGColor
    mask.applyShadow(shadow: content.style.shadow)

    let popup = UIView(
      frame: CGRect(
        x: 0,
        y: 0,
        width: content.frame.size.width,
        height: content.frame.size.height + padding + frame.size.height))
    popup.addSubview(content)
    popup.layer.insertSublayer(mask, atIndex: 0)
    return popup
  }

  // MARK: Hit Test
  public override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
    let hitFrame = UIEdgeInsetsInsetRect(bounds, hitRangeInsets)
    return hitFrame.contains(point)
  }
}
