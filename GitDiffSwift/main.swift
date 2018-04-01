//
//  main.swift
//  GitDiffSwift
//
//  Created by Steven Deutsch on 2/7/18.
//  Copyright © 2018 GitDiffSwift. All rights reserved.
//

import Foundation

var input = """
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 06c2277..c3451a3 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -6,6 +6,12 @@ The changelog for `MessageKit`. Also see the [releases](https://github.com/Messa

## Upcoming release

+### Added
+
+- Added `detectorAttributes(for:and:at:)` method to `MessagesDisplayDelegate` allowing `DetectorType`
+attributes to be set outside of the cell.
+[#397](https://github.com/MessageKit/MessageKit/pull/397) by [@SD10](https://github.com/sd10).
+
### Fixed

- Fixed `indexPathForLastItem` bug when `numberOfSections` equal to 1.
@@ -16,6 +22,10 @@ The changelog for `MessageKit`. Also see the [releases](https://github.com/Messa

### Changed

+- **Breaking Change** The `MessageLabel` properties `addressAttributes`, `dateAttributes`, `phoneNumberAttributes`,
+and `urlAttributes` are now read only. Please use `setAttributes(_:detector:)` to set these properties.
+[#397](https://github.com/MessageKit/MessageKit/pull/397) by [@SD10](https://github.com/sd10).
+
- **Breaking Change** Removed the generic constraint `<ContentView: UIView>` from `MessageCollectionViewCell`.
[#391](https://github.com/MessageKit/MessageKit/pull/391) by [@SD10](https://github.com/sd10).

diff --git a/Example/Sources/ConversationViewController.swift b/Example/Sources/ConversationViewController.swift
index 67f4705..1d04b3b 100644
--- a/Example/Sources/ConversationViewController.swift
+++ b/Example/Sources/ConversationViewController.swift
@@ -281,16 +281,26 @@ extension ConversationViewController: MessagesDataSource {

extension ConversationViewController: MessagesDisplayDelegate {

+    // MARK: - Text Messages
+
+    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
+        return isFromCurrentSender(message: message) ? .white : .darkText
+    }
+
+    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
+        return [.foregroundColor: UIColor.darkText, .underlineStyle: NSUnderlineStyle.styleSingle.rawValue]
+    }
+
+    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
+        return [.url, .address, .phoneNumber, .date]
+    }
+
// MARK: - All Messages

func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
}

-    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
-        return isFromCurrentSender(message: message) ? .white : .darkText
-    }
-
func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
return .bubbleTail(corner, .curved)
@@ -326,10 +336,6 @@ extension ConversationViewController: MessagesDisplayDelegate {

extension ConversationViewController: MessagesLayoutDelegate {

-    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
-        return [.url, .address, .phoneNumber, .date]
-    }
-
func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
}
diff --git a/Sources/Controllers/MessagesViewController.swift b/Sources/Controllers/MessagesViewController.swift
index 11d31e0..6438409 100644
--- a/Sources/Controllers/MessagesViewController.swift
+++ b/Sources/Controllers/MessagesViewController.swift
@@ -232,8 +232,14 @@ extension MessagesViewController: UICollectionViewDataSource {
switch message.data {
case .text, .attributedText, .emoji:
let cell = messagesCollectionView.dequeueReusableCell(TextMessageCell.self, for: indexPath)
-            let detectors = displayDelegate.enabledDetectors(for: message, at: indexPath, in: messagesCollectionView)
let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
+            let detectors = displayDelegate.enabledDetectors(for: message, at: indexPath, in: messagesCollectionView)
+            cell.messageLabel.configure {
+                for detector in detectors {
+                    let attributes = displayDelegate.detectorAttributes(for: detector, and: message, at: indexPath)
+                    cell.messageLabel.setAttributes(attributes, detector: detector)
+                }
+            }
cell.configure(message, textColor, detectors)
commonConfigure(cell)
return cell
diff --git a/Sources/Protocols/MessagesDisplayDelegate.swift b/Sources/Protocols/MessagesDisplayDelegate.swift
index c3421ea..da034ba 100644
--- a/Sources/Protocols/MessagesDisplayDelegate.swift
+++ b/Sources/Protocols/MessagesDisplayDelegate.swift
@@ -110,6 +110,15 @@ public protocol MessagesDisplayDelegate: AnyObject {
/// The default value returned by this method is all available detector types.
func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType]

+    /// Specifies the attributes for a given `DetectorType`
+    ///
+    /// - Parameters:
+    ///   - detector: The `DetectorType` for the applied attributes.
+    ///   - message: A `MessageType` with a `MessageData` case of `.text` or `.attributedText`
+    ///   to which the detectors will apply.
+    ///   - indexPath: The `IndexPath` of the cell.
+    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey: Any]
+
// MARK: - Location Messages

/// Ask the delegate for a LocationMessageSnapshotOptions instance to customize the MapView on the given message
@@ -196,6 +205,10 @@ public extension MessagesDisplayDelegate {
return []
}

+    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey: Any] {
+        return [:]
+    }
+
// MARK: - Location Messages Defaults

func snapshotOptionsForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LocationMessageSnapshotOptions {
diff --git a/Sources/Views/Cells/TextMessageCell.swift b/Sources/Views/Cells/TextMessageCell.swift
index df31221..9d265dc 100644
--- a/Sources/Views/Cells/TextMessageCell.swift
+++ b/Sources/Views/Cells/TextMessageCell.swift
@@ -67,7 +67,9 @@ open class TextMessageCell: MessageCollectionViewCell {
messageLabel.fillSuperview()
}

-    open func configure(_ message: MessageType, _ textColor: UIColor, _ detectors: [DetectorType]) {
+    open func configure(_ message: MessageType,
+                        _ textColor: UIColor,
+                        _ detectors: [DetectorType]) {

messageLabel.configure {
messageLabel.textColor = textColor
diff --git a/Sources/Views/MessageLabel.swift b/Sources/Views/MessageLabel.swift
index 82e710f..f95aaa5 100644
--- a/Sources/Views/MessageLabel.swift
+++ b/Sources/Views/MessageLabel.swift
@@ -126,31 +126,39 @@ open class MessageLabel: UILabel {
}
}

-    open var addressAttributes: [NSAttributedStringKey: Any] = [:] {
-        didSet {
-            updateAttributes(for: .address)
-            if !isConfiguring { setNeedsDisplay() }
-        }
-    }
+    private var attributesNeedUpdate = false

-    open var dateAttributes: [NSAttributedStringKey: Any] = [:] {
-        didSet {
-            updateAttributes(for: .date)
-            if !isConfiguring { setNeedsDisplay() }
-        }
-    }
+    private static var defaultAttributes: [NSAttributedStringKey: Any] = {
+        return [
+            NSAttributedStringKey.foregroundColor: UIColor.darkText,
+            NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
+            NSAttributedStringKey.underlineColor: UIColor.darkText
+        ]
+    }()

-    open var phoneNumberAttributes: [NSAttributedStringKey: Any] = [:] {
-        didSet {
-            updateAttributes(for: .phoneNumber)
-            if !isConfiguring { setNeedsDisplay() }
-        }
-    }
+    open internal(set) var addressAttributes: [NSAttributedStringKey: Any] = defaultAttributes

-    open var urlAttributes: [NSAttributedStringKey: Any] = [:] {
-        didSet {
-            updateAttributes(for: .url)
-            if !isConfiguring { setNeedsDisplay() }
+    open internal(set) var dateAttributes: [NSAttributedStringKey: Any] = defaultAttributes
+
+    open internal(set) var phoneNumberAttributes: [NSAttributedStringKey: Any] = defaultAttributes
+
+    open internal(set) var urlAttributes: [NSAttributedStringKey: Any] = defaultAttributes
+
+    public func setAttributes(_ attributes: [NSAttributedStringKey: Any], detector: DetectorType) {
+        switch detector {
+        case .phoneNumber:
+            phoneNumberAttributes = attributes
+        case .address:
+            addressAttributes = attributes
+        case .date:
+            dateAttributes = attributes
+        case .url:
+            urlAttributes = attributes
+        }
+        if isConfiguring {
+            attributesNeedUpdate = true
+        } else {
+            updateAttributes(for: [detector])
}
}

@@ -158,22 +166,8 @@ open class MessageLabel: UILabel {

public override init(frame: CGRect) {
super.init(frame: frame)
-
-        // Message Label Specific
self.numberOfLines = 0
self.lineBreakMode = .byWordWrapping
-
-        let defaultAttributes: [NSAttributedStringKey: Any] = [
-          NSAttributedStringKey.foregroundColor: self.textColor,
-          NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
-          NSAttributedStringKey.underlineColor: self.textColor
-        ]
-
-        self.addressAttributes = defaultAttributes
-        self.dateAttributes = defaultAttributes
-        self.phoneNumberAttributes = defaultAttributes
-        self.urlAttributes = defaultAttributes
-
}

public required init?(coder aDecoder: NSCoder) {
@@ -199,6 +193,10 @@ open class MessageLabel: UILabel {
public func configure(block: () -> Void) {
isConfiguring = true
block()
+        if attributesNeedUpdate {
+            updateAttributes(for: enabledDetectors)
+        }
+        attributesNeedUpdate = false
isConfiguring = false
setNeedsDisplay()
}
@@ -254,21 +252,22 @@ open class MessageLabel: UILabel {
return style
}

-    private func updateAttributes(for detectorType: DetectorType) {
+    private func updateAttributes(for detectors: [DetectorType]) {

guard let attributedText = attributedText, attributedText.length > 0 else { return }
let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)

-        guard let rangeTuples = rangesForDetectors[detectorType] else { return }
-
-        for (range, _)  in rangeTuples {
-            let attributes = detectorAttributes(for: detectorType)
-            mutableAttributedString.addAttributes(attributes, range: range)
-        }
+        for detector in detectors {
+            guard let rangeTuples = rangesForDetectors[detector] else { return }

-        let updatedString = NSAttributedString(attributedString: mutableAttributedString)
-        textStorage.setAttributedString(updatedString)
+            for (range, _)  in rangeTuples {
+                let attributes = detectorAttributes(for: detector)
+                mutableAttributedString.addAttributes(attributes, range: range)
+            }

+            let updatedString = NSAttributedString(attributedString: mutableAttributedString)
+            textStorage.setAttributedString(updatedString)
+        }
}

private func detectorAttributes(for detectorType: DetectorType) -> [NSAttributedStringKey: Any] {
"""

let diffs = DiffParser(input: input).extractDiffs()

print("COUNT: ", diffs.count)

for diff in diffs {
    print(diff.description)
}


