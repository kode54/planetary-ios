//
//  PostCellView.swift
//  FBTT
//
//  Created by Christoph on 4/18/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import ImageSlideshow
import UIKit
import SkeletonView

class PostCellView: KeyValueView {

    let verticalSpace: CGFloat = 5

    private lazy var seeMoreString: NSAttributedString = {
        let seeMore = NSMutableAttributedString(string: "... \(Text.seeMore.text)")
        let styler = MarkdownStyler()
        styler.style(seeMore: seeMore)
        let range = (seeMore.string as NSString).range(of: Text.seeMore.text)
        seeMore.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.tint.default], range: range)
        return seeMore
    }()

    var displayHeader: Bool = true {
        didSet {
            self.headerView.isHidden = !self.displayHeader
            self.textViewTopConstraint.constant = self.textViewTopInset
        }
    }

    var allowSpaceUnderGallery = true

    var keyValue: KeyValue?
    private lazy var headerView = PostHeaderView()

    private lazy var textView: UITextView = {
        let view = UITextView.forAutoLayout()
        view.addGestureRecognizer(self.tapGesture.recognizer)
        view.isEditable = false
        view.isScrollEnabled = false
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.lineBreakMode = .byTruncatingTail
        view.isSkeletonable = true
        view.linesCornerRadius = 30
        view.backgroundColor = .cardBackground
        return view
    }()

    var textViewTopConstraint = NSLayoutConstraint()
    
    /// Activate or deactivate this constraint to make text view have no height (5px actually),
    /// for instance, if the text is empty
    var textViewZeroHeightConstraint = NSLayoutConstraint()

    var textViewTopInset: CGFloat {
        if self.displayHeader {
            return Layout.profileThumbSize + Layout.verticalSpacing + self.verticalSpace
        } else {
            return self.verticalSpace
        }
    }

    var fullPostText = NSAttributedString() {
        didSet {
            // reset cached text, but don't recalculate yet so we don't do unnecessary work.
            self.truncationData = nil
        }
    }

    var truncationData: (text: NSAttributedString, width: CGFloat)?
    private let emptyTruncationData = (text: NSAttributedString.empty, width: CGFloat(0))

    var truncationLimit: TruncationSettings? {
        didSet {
            if let oldValue = oldValue, let newValue = truncationLimit, newValue.to == oldValue.to, newValue.over == oldValue.over {
                // Don't recalculate truncated state
                return
            } else {
                self.truncationData = nil
                self.configureTruncatedState()
            }
        }
    }

    var shouldTruncate: Bool {
        return self.truncationLimit != nil
    }

    var textIsExpanded = false {
        didSet {
            self.updateFullPostText()
            self.configureTruncatedState()
        }
    }

    func toggleExpanded() {
        self.textIsExpanded = !self.textIsExpanded
    }

    private func updateFullPostText() {
        guard self.textIsExpanded else { return }
        guard let keyValue = self.keyValue, keyValue.value.content.isPost else { return }
        let string = Caches.text.from(keyValue).mutable()
        self.fullPostText = string
    }

    func configureTruncatedState() {
        self.calculateTruncationDataIfNecessary()
        self.textView.attributedText = self.truncationData?.text ?? self.fullPostText
        
        //not so clean but it gest likes displaying.
        if self.textView.attributedText.string.isSingleEmoji && self.keyValue?.value.content.type == Planetary.ContentType.vote {
            self.textView.font = UIFont.post.body.withSize(200)
            self.textView.textAlignment = .center
        } else if self.textView.attributedText.string.isSingleEmoji,
             let post = self.keyValue?.value.content.post,
              !post.hasBlobs {
              self.textView.font = UIFont.post.body.withSize(200)
              self.textView.textAlignment = .center
          } else {
              self.textView.textAlignment = .natural
        }
        
        self.textViewZeroHeightConstraint.isActive = self.textView.attributedText.string.isEmpty
    }

    /// Calculates the truncation data, but only when necessary.  In some cases, an optimized
    /// answer can be used because `NSAttributedString.truncating()` is very
    /// expensive, especially during scrolling.
    func calculateTruncationDataIfNecessary() {

        // skip calculation if not necessary
        guard let limit = self.truncationLimit else { return }
        guard self.truncationData == nil else { return }
        guard !self.textIsExpanded else { return }

        // truncation cannot be calculated without a height
        // so return an optimized answer to allow text layout
        guard self.textView.frame.width > 0 else {
            self.truncationData = self.emptyTruncationData
            return
        }

        // calculate with a valid width
        let width = self.textView.frame.width
        let text = fullPostText.truncating(with: self.seeMoreString, settings: limit, width: width)
        self.truncationData = (text: text, width: width)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // this busts the cache for the truncationData,
        // which must be recalculated when the width is changed
        if let width = self.truncationData?.width, self.textView.frame.width != width {
            self.truncationData = nil
            self.configureTruncatedState()
        }
    }

    // the gallery view allows custom insets for the actual content
    // inside of it, and this value was chosen to allow for a specific
    // distance between the content top and the northern text view
    private let galleryView = GalleryView()
    private var galleryViewZeroHeightConstraint: NSLayoutConstraint!
    private var galleryViewFullHeightConstraint: NSLayoutConstraint!
    private var galleryViewBottomConstraint: NSLayoutConstraint?

    // MARK: Lifecycle

    init() {
        super.init(frame: CGRect.zero)
        self.useAutoLayout()
        
        self.backgroundColor = .cardBackground

        Layout.fillTop(of: self, with: self.headerView, insets: .topLeftRight)

        let (top, _, _) = Layout.fillTop(of: self,
                                         with: self.textView,
                                         insets: UIEdgeInsets(top: self.textViewTopInset, left: Layout.postSideMargins, bottom: 0, right: -Layout.postSideMargins),
                                         respectSafeArea: false)
        self.textViewTopConstraint = top
        
        self.textViewZeroHeightConstraint = NSLayoutConstraint(item: self.textView,
                                                               attribute: .height,
                                                               relatedBy: .equal,
                                                               toItem: nil,
                                                               attribute: .notAnAttribute,
                                                               multiplier: 1,
                                                               constant: 5)
        self.textViewZeroHeightConstraint.isActive = false

        self.addSubview(self.galleryView)
        self.galleryView.pinTop(toBottomOf: self.textView, constant: 5)
        self.galleryView.pinLeftToSuperview()
        self.galleryView.constrainWidth(to: self)
        self.galleryViewBottomConstraint = self.galleryView.pinBottomToSuperviewBottom()

        self.galleryViewFullHeightConstraint = self.galleryView.heightAnchor.constraint(equalTo: self.galleryView.widthAnchor)
        self.galleryViewZeroHeightConstraint = self.galleryView.heightAnchor.constraint(equalToConstant: 0)
        self.galleryViewZeroHeightConstraint.isActive = true
        
        self.isSkeletonable = true
    }

    convenience init(keyValue: KeyValue) {
        assert(keyValue.value.content.isPost)
        self.init()
        self.update(with: keyValue)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: KeyValueUpdateable

    override func update(with keyValue: KeyValue) {
        self.keyValue = keyValue
        self.headerView.update(with: keyValue)

        if let vote = keyValue.value.content.vote {
            let expression: String
            if vote.vote.value > 0 {
                expression = "💜"
            } else {
                expression = "💔"
            }
            
            self.fullPostText = NSAttributedString(string: expression)
            self.textView.text = expression
            self.configureTruncatedState()
            
            self.galleryViewFullHeightConstraint.isActive = false
            self.galleryViewZeroHeightConstraint.isActive = true
            self.galleryViewBottomConstraint?.constant = 0
        } else if let post = keyValue.value.content.post {
            let text = self.shouldTruncate ? Caches.truncatedText.from(keyValue) : Caches.text.from(keyValue)
            
            self.fullPostText = text
            self.configureTruncatedState()

            self.galleryViewFullHeightConstraint.isActive = post.hasBlobs
            self.galleryViewZeroHeightConstraint.isActive = !post.hasBlobs
            self.galleryViewBottomConstraint?.constant = (post.hasBlobs && self.allowSpaceUnderGallery) ? -Layout.verticalSpacing : 0
            self.galleryView.update(with: post)
        } else {
            return
        }
        

        

        // always do this in case of constraint changes
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
