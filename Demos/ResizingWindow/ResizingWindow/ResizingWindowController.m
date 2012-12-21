//
//	ResizingWindowController.m
//	ResizingWindow
//
//	Created by Justin Spahr-Summers on 2012-12-12.
//	Copyright (c) 2012 GitHub. All rights reserved.
//

#import "ResizingWindowController.h"

@interface ResizingWindowController ()

@property (nonatomic, strong, readonly) NSView *contentView;

@end

@implementation ResizingWindowController

#pragma mark Properties

- (NSView *)contentView {
	return self.window.contentView;
}

#pragma mark Lifecycle

- (id)init {
	return [self initWithWindowNibName:@"ResizingWindow"];
}

- (void)windowDidLoad {
	[super windowDidLoad];

	NSTextField *nameLabel = [self labelWithString:NSLocalizedString(@"Name", @"")];
	NSTextField *emailLabel = [self labelWithString:NSLocalizedString(@"Email Address", @"")];

	RACSignal *labelWidth = [RACSignal max:@[ nameLabel.rcl_intrinsicContentSizeSignal.width, emailLabel.rcl_intrinsicContentSizeSignal.width ]];
	RACSignal *padding = [RACSignal return:@8];

	NSTextField *nameField = [self textFieldWithString:@""];
	NSTextField *emailField = [self textFieldWithString:@""];

	RACTupleUnpack(RACSignal *nameRect, RACSignal *emailRect) = [[self.contentView.rcl_frameSignal
		insetWidth:[RACSignal return:@32] height:[RACSignal return:@16]]
		divideWithAmount:nameField.rcl_intrinsicContentSizeSignal.height padding:padding fromEdge:CGRectMaxYEdge];

	RACTupleUnpack(RACSignal *nameLabelRect, RACSignal *nameFieldRect) = [nameRect divideWithAmount:labelWidth padding:padding fromEdge:CGRectMinXEdge];

	// Don't animate setting the initial frames.
	RAC(nameLabel, rcl_alignmentRect) = [nameLabelRect alignBaseline:nameLabel.rcl_baselineSignal toBaseline:nameField.rcl_baselineSignal ofRect:nameFieldRect];
	RAC(nameField, frame) = [nameFieldRect take:1];

	[[[nameFieldRect skip:1] animateWithDuration:0.5] subscribeNext:^(NSValue *rect) {
		// Can't lift this because lolappkit.
		[nameField.animator setFrame:rect.med_rectValue];
	}];

	RACTupleUnpack(RACSignal *emailLabelRect, RACSignal *emailFieldRect) = [[emailRect
		sliceWithAmount:emailField.rcl_intrinsicContentSizeSignal.height fromEdge:CGRectMaxYEdge]
		divideWithAmount:labelWidth padding:padding fromEdge:CGRectMinXEdge];

	RAC(emailLabel, rcl_alignmentRect) = [emailLabelRect alignBaseline:emailLabel.rcl_baselineSignal toBaseline:emailField.rcl_baselineSignal ofRect:emailFieldRect];
	RAC(emailField, rcl_alignmentRect) = emailFieldRect;
}

#pragma mark View Creation

- (NSTextField *)labelWithString:(NSString *)string {
	NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
	label.editable = NO;
	label.selectable = NO;
	label.bezeled = NO;
	label.drawsBackground = NO;
	label.stringValue = string;
	label.font = [NSFont systemFontOfSize:8];
	[label sizeToFit];

	// We don't actually use autoresizing to move these views, but rather to
	// keep them pinned in the absence of any movement.
	label.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;

	[self.contentView addSubview:label];
	return label;
}

- (NSTextField *)textFieldWithString:(NSString *)string {
	NSTextField *textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
	textField.stringValue = string;
	[textField sizeToFit];

	// We don't actually use autoresizing to move these views, but rather to
	// keep them pinned in the absence of any movement.
	textField.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;

	[self.contentView addSubview:textField];
	return textField;
}

@end
