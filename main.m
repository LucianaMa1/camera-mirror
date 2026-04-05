#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>

static NSString * const kSignatureKey = @"mirror.signature";
static NSString * const kSignatureColorKey = @"mirror.signatureColor";
static NSString * const kSignatureFontSizeKey = @"mirror.signatureFontSize";
static NSString * const kDiameterKey = @"mirror.diameter";
static NSString * const kShapeKey = @"mirror.shape";
static NSString * const kMirrorOriginXKey = @"mirror.windowOriginX";
static NSString * const kMirrorOriginYKey = @"mirror.windowOriginY";
static NSString * const kOverlayOriginXKey = @"mirror.overlayOriginX";
static NSString * const kOverlayOriginYKey = @"mirror.overlayOriginY";

typedef NS_ENUM(NSInteger, MirrorShape) {
    MirrorShapeCircle = 0,
    MirrorShapeRoundedSquare = 1,
    MirrorShapeSoftSquare = 2
};

@interface MirrorConfig : NSObject <NSCopying>
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, strong) NSColor *signatureColor;
@property (nonatomic, assign) CGFloat signatureFontSize;
@property (nonatomic, assign) CGFloat diameter;
@property (nonatomic, assign) MirrorShape shape;
@property (nonatomic, assign) CGFloat mirrorOriginX;
@property (nonatomic, assign) CGFloat mirrorOriginY;
@property (nonatomic, assign) CGFloat overlayOriginX;
@property (nonatomic, assign) CGFloat overlayOriginY;
+ (instancetype)defaults;
@end

@implementation MirrorConfig
+ (instancetype)defaults {
    MirrorConfig *config = [[MirrorConfig alloc] init];
    config.signature = @"shine softly";
    config.signatureColor = [NSColor colorWithCalibratedRed:1.0 green:0.72 blue:0.80 alpha:1.0];
    config.signatureFontSize = 24.0;
    config.diameter = 300.0;
    config.shape = MirrorShapeCircle;
    config.mirrorOriginX = CGFLOAT_MAX;
    config.mirrorOriginY = CGFLOAT_MAX;
    config.overlayOriginX = CGFLOAT_MAX;
    config.overlayOriginY = CGFLOAT_MAX;
    return config;
}

- (id)copyWithZone:(NSZone *)zone {
    MirrorConfig *copy = [[[self class] allocWithZone:zone] init];
    copy.signature = [self.signature copy];
    copy.signatureColor = self.signatureColor;
    copy.signatureFontSize = self.signatureFontSize;
    copy.diameter = self.diameter;
    copy.shape = self.shape;
    copy.mirrorOriginX = self.mirrorOriginX;
    copy.mirrorOriginY = self.mirrorOriginY;
    copy.overlayOriginX = self.overlayOriginX;
    copy.overlayOriginY = self.overlayOriginY;
    return copy;
}
@end

@interface SettingsStore : NSObject
+ (MirrorConfig *)loadConfig;
+ (void)saveConfig:(MirrorConfig *)config;
@end

@implementation SettingsStore
+ (MirrorConfig *)loadConfig {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    MirrorConfig *config = [MirrorConfig defaults];

    if ([defaults objectForKey:kSignatureKey] != nil) {
        NSString *signature = [defaults stringForKey:kSignatureKey];
        config.signature = signature;
    }

    NSData *signatureColorData = [defaults dataForKey:kSignatureColorKey];
    if (signatureColorData != nil) {
        NSColor *storedColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:signatureColorData error:nil];
        if (storedColor != nil) {
            config.signatureColor = storedColor;
        }
    }

    double signatureFontSize = [defaults doubleForKey:kSignatureFontSizeKey];
    if (signatureFontSize > 0) {
        config.signatureFontSize = (CGFloat)signatureFontSize;
    }

    double diameter = [defaults doubleForKey:kDiameterKey];
    if (diameter > 0) {
        config.diameter = (CGFloat)diameter;
    }

    NSInteger shape = [defaults integerForKey:kShapeKey];
    if (shape >= MirrorShapeCircle && shape <= MirrorShapeSoftSquare) {
        config.shape = (MirrorShape)shape;
    }

    if ([defaults objectForKey:kMirrorOriginXKey] != nil) {
        config.mirrorOriginX = [defaults doubleForKey:kMirrorOriginXKey];
    }

    if ([defaults objectForKey:kMirrorOriginYKey] != nil) {
        config.mirrorOriginY = [defaults doubleForKey:kMirrorOriginYKey];
    }

    if ([defaults objectForKey:kOverlayOriginXKey] != nil) {
        config.overlayOriginX = [defaults doubleForKey:kOverlayOriginXKey];
    }

    if ([defaults objectForKey:kOverlayOriginYKey] != nil) {
        config.overlayOriginY = [defaults doubleForKey:kOverlayOriginYKey];
    }

    return config;
}

+ (void)saveConfig:(MirrorConfig *)config {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:config.signature forKey:kSignatureKey];
    [defaults setDouble:config.diameter forKey:kDiameterKey];
    [defaults setInteger:config.shape forKey:kShapeKey];
    [defaults setDouble:config.signatureFontSize forKey:kSignatureFontSizeKey];
    [defaults setDouble:config.mirrorOriginX forKey:kMirrorOriginXKey];
    [defaults setDouble:config.mirrorOriginY forKey:kMirrorOriginYKey];
    [defaults setDouble:config.overlayOriginX forKey:kOverlayOriginXKey];
    [defaults setDouble:config.overlayOriginY forKey:kOverlayOriginYKey];

    NSData *signatureColorData = [NSKeyedArchiver archivedDataWithRootObject:config.signatureColor requiringSecureCoding:YES error:nil];
    if (signatureColorData != nil) {
        [defaults setObject:signatureColorData forKey:kSignatureColorKey];
    }
}
@end

@interface MirrorContentView : NSView
- (void)applyConfig:(MirrorConfig *)config;
@property (nonatomic, copy) void (^onToggleSettings)(void);
@property (nonatomic, copy) void (^onQuit)(void);
@property (nonatomic, copy) void (^onDragMove)(NSPoint origin);
@end

@interface TextOverlayView : NSView
- (void)applyConfig:(MirrorConfig *)config;
- (NSSize)preferredSize;
@property (nonatomic, copy) void (^onDragMove)(NSPoint origin);
@property (nonatomic, copy) void (^onOpenSettings)(void);
@end

@interface MirrorContentView ()
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CAGradientLayer *overlayGradient;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSButton *settingsButton;
@property (nonatomic, strong) NSButton *quitButton;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) MirrorConfig *currentConfig;
@property (nonatomic, strong) NSTrackingArea *hoverTrackingArea;
@property (nonatomic, assign) NSPoint dragStartLocation;
@property (nonatomic, assign) NSPoint dragStartWindowOrigin;
@end

@interface TextOverlayView ()
@property (nonatomic, strong) NSTextField *signatureLabel;
@property (nonatomic, strong) MirrorConfig *currentConfig;
@property (nonatomic, strong) NSTrackingArea *dragTrackingArea;
@property (nonatomic, assign) NSPoint dragStartLocation;
@property (nonatomic, assign) NSPoint dragStartOrigin;
@end

@implementation MirrorContentView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _session = [[AVCaptureSession alloc] init];
        _sessionQueue = dispatch_queue_create("mirror.camera.session", DISPATCH_QUEUE_SERIAL);
        [self setupView];
        [self configureCameraAccess];
    }
    return self;
}

- (void)setupView {
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
    self.layer.masksToBounds = YES;

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:self.previewLayer];

    self.overlayGradient = [CAGradientLayer layer];
    self.overlayGradient.colors = @[
        (__bridge id)NSColor.clearColor.CGColor,
        (__bridge id)[NSColor colorWithCalibratedWhite:0.02 alpha:0.18].CGColor,
        (__bridge id)[NSColor colorWithCalibratedWhite:0.02 alpha:0.76].CGColor
    ];
    self.overlayGradient.locations = @[@0.0, @0.55, @1.0];
    [self.layer addSublayer:self.overlayGradient];

    self.statusLabel = [self makeLabel];
    self.statusLabel.alignment = NSTextAlignmentCenter;
    self.statusLabel.font = [NSFont systemFontOfSize:15.0 weight:NSFontWeightMedium];
    self.statusLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.92];
    self.statusLabel.maximumNumberOfLines = 2;
    self.statusLabel.hidden = YES;
    [self addSubview:self.statusLabel];

    self.settingsButton = [NSButton buttonWithTitle:@"•" target:self action:@selector(toggleSettings:)];
    self.settingsButton.bezelStyle = NSBezelStyleRegularSquare;
    self.settingsButton.bordered = NO;
    self.settingsButton.font = [NSFont systemFontOfSize:18.0 weight:NSFontWeightBold];
    self.settingsButton.contentTintColor = [NSColor colorWithWhite:1.0 alpha:0.95];
    self.settingsButton.wantsLayer = YES;
    self.settingsButton.layer.backgroundColor = [NSColor colorWithWhite:0.08 alpha:0.55].CGColor;
    self.settingsButton.layer.cornerRadius = 14.0;
    self.settingsButton.alphaValue = 0.0;
    self.settingsButton.hidden = YES;
    self.settingsButton.toolTip = @"Open or hide settings";
    [self addSubview:self.settingsButton];

    self.quitButton = [NSButton buttonWithTitle:@"×" target:self action:@selector(quitApp:)];
    self.quitButton.bezelStyle = NSBezelStyleRegularSquare;
    self.quitButton.bordered = NO;
    self.quitButton.font = [NSFont systemFontOfSize:18.0 weight:NSFontWeightSemibold];
    self.quitButton.contentTintColor = [NSColor colorWithWhite:1.0 alpha:0.95];
    self.quitButton.wantsLayer = YES;
    self.quitButton.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.65 green:0.11 blue:0.16 alpha:0.72].CGColor;
    self.quitButton.layer.cornerRadius = 14.0;
    self.quitButton.alphaValue = 0.0;
    self.quitButton.hidden = YES;
    self.quitButton.toolTip = @"Quit Camera Mirror";
    [self addSubview:self.quitButton];
}

- (NSTextField *)makeLabel {
    NSTextField *label = [NSTextField labelWithString:@""];
    label.backgroundColor = NSColor.clearColor;
    label.bordered = NO;
    label.drawsBackground = NO;
    label.lineBreakMode = NSLineBreakByTruncatingTail;

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.45];
    shadow.shadowBlurRadius = 10.0;
    shadow.shadowOffset = NSMakeSize(0, -1);
    label.shadow = shadow;
    return label;
}

- (void)layout {
    [super layout];

    self.previewLayer.frame = self.bounds;
    self.overlayGradient.frame = self.bounds;
    [self applyShapeMask];

    CGFloat buttonSize = MAX(self.bounds.size.width * 0.12, 28.0);
    CGFloat topInset = MAX(self.bounds.size.width * 0.06, 14.0);
    CGFloat buttonSpacing = MAX(buttonSize * 0.28, 8.0);
    CGFloat totalButtonsWidth = (buttonSize * 2.0) + buttonSpacing;
    CGFloat buttonStartX = (self.bounds.size.width - totalButtonsWidth) / 2.0;
    CGFloat buttonY = self.bounds.size.height - topInset - buttonSize;
    self.settingsButton.frame = NSMakeRect(buttonStartX, buttonY, buttonSize, buttonSize);
    self.settingsButton.layer.cornerRadius = buttonSize / 2.0;
    self.quitButton.frame = NSMakeRect(NSMaxX(self.settingsButton.frame) + buttonSpacing, buttonY, buttonSize, buttonSize);
    self.quitButton.layer.cornerRadius = buttonSize / 2.0;
    self.statusLabel.frame = NSMakeRect(self.bounds.size.width * 0.18, (self.bounds.size.height / 2.0) - 22.0, self.bounds.size.width * 0.64, 44.0);
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    if (self.hoverTrackingArea != nil) {
        [self removeTrackingArea:self.hoverTrackingArea];
    }

    self.hoverTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                          options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect
                                                            owner:self
                                                         userInfo:nil];
    [self addTrackingArea:self.hoverTrackingArea];
}

- (void)applyConfig:(MirrorConfig *)config {
    self.currentConfig = config;
    [self setNeedsLayout:YES];
}

- (void)applyShapeMask {
    CGFloat minSide = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat cornerRadius = minSide / 2.0;

    if (self.currentConfig.shape == MirrorShapeRoundedSquare) {
        cornerRadius = minSide * 0.18;
    } else if (self.currentConfig.shape == MirrorShapeSoftSquare) {
        cornerRadius = minSide * 0.30;
    }

    self.layer.cornerRadius = cornerRadius;
}

- (void)configureCameraAccess {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized: {
            [self startSession];
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            [self showStatus:@"Requesting camera access…"];
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [self hideStatus];
                        [self startSession];
                    } else {
                        [self showStatus:@"Camera access denied.\nPlease allow it in System Settings."];
                    }
                });
            }];
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted: {
            [self showStatus:@"Camera access denied.\nPlease allow it in System Settings."];
            break;
        }
    }
}

- (void)startSession {
    [self showStatus:@"Starting camera…"];
    dispatch_async(self.sessionQueue, ^{
        if (self.session.running) {
            return;
        }

        [self.session beginConfiguration];
        self.session.sessionPreset = AVCaptureSessionPresetHigh;

        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        if (device == nil) {
            device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        }

        if (device == nil) {
            [self.session commitConfiguration];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showStatus:@"No camera detected."];
            });
            return;
        }

        NSError *inputError = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&inputError];
        if (inputError != nil || input == nil) {
            [self.session commitConfiguration];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showStatus:@"Unable to open the camera."];
            });
            return;
        }

        if ([self.session canAddInput:input]) {
            [self.session addInput:input];
        }

        [self.session commitConfiguration];

        dispatch_async(dispatch_get_main_queue(), ^{
            AVCaptureConnection *connection = self.previewLayer.connection;
            if (connection != nil && connection.isVideoMirroringSupported) {
                connection.automaticallyAdjustsVideoMirroring = NO;
                connection.videoMirrored = YES;
            }
            [self hideStatus];
        });

        [self.session startRunning];
    });
}

- (void)showStatus:(NSString *)message {
    self.statusLabel.stringValue = message ?: @"";
    self.statusLabel.hidden = NO;
}

- (void)hideStatus {
    self.statusLabel.hidden = YES;
}

- (void)toggleSettings:(id)sender {
    if (self.onToggleSettings != nil) {
        self.onToggleSettings();
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self setSettingsButtonVisible:YES animated:YES];
}

- (void)mouseExited:(NSEvent *)event {
    [self setSettingsButtonVisible:NO animated:YES];
}

- (void)setSettingsButtonVisible:(BOOL)visible animated:(BOOL)animated {
    self.settingsButton.hidden = NO;
    self.quitButton.hidden = NO;
    CGFloat targetAlpha = visible ? 1.0 : 0.0;

    if (animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.14;
            self.settingsButton.animator.alphaValue = targetAlpha;
            self.quitButton.animator.alphaValue = targetAlpha;
        } completionHandler:^{
            self.settingsButton.hidden = !visible;
            self.quitButton.hidden = !visible;
        }];
    } else {
        self.settingsButton.alphaValue = targetAlpha;
        self.settingsButton.hidden = !visible;
        self.quitButton.alphaValue = targetAlpha;
        self.quitButton.hidden = !visible;
    }
}

- (void)quitApp:(id)sender {
    if (self.onQuit != nil) {
        self.onQuit();
    }
}

- (void)mouseDown:(NSEvent *)event {
    if (event.type != NSEventTypeLeftMouseDown) {
        [super mouseDown:event];
        return;
    }

    self.dragStartLocation = [NSEvent mouseLocation];
    if (self.window != nil) {
        self.dragStartWindowOrigin = self.window.frame.origin;
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (self.window == nil) {
        [super mouseDragged:event];
        return;
    }

    NSPoint currentLocation = [NSEvent mouseLocation];
    CGFloat deltaX = currentLocation.x - self.dragStartLocation.x;
    CGFloat deltaY = currentLocation.y - self.dragStartLocation.y;

    NSPoint newOrigin = NSMakePoint(self.dragStartWindowOrigin.x + deltaX, self.dragStartWindowOrigin.y + deltaY);
    [self.window setFrameOrigin:newOrigin];

    if (self.onDragMove != nil) {
        self.onDragMove(newOrigin);
    }
}

@end

@implementation TextOverlayView

- (NSFont *)signatureFontWithSize:(CGFloat)size {
    return [NSFont fontWithName:@"Snell Roundhand Bold" size:size] ?: ([NSFont fontWithName:@"Didot" size:size] ?: [NSFont systemFontOfSize:size weight:NSFontWeightMedium]);
}

- (BOOL)isFlipped {
    return YES;
}

- (void)configureWrappingLabel:(NSTextField *)label {
    label.maximumNumberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.cell.wraps = YES;
    label.cell.scrollable = NO;
    label.usesSingleLineMode = NO;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = NSColor.clearColor.CGColor;

        self.signatureLabel = [NSTextField wrappingLabelWithString:@""];
        self.signatureLabel.backgroundColor = NSColor.clearColor;
        self.signatureLabel.bordered = NO;
        self.signatureLabel.drawsBackground = NO;
        self.signatureLabel.alignment = NSTextAlignmentLeft;
        [self configureWrappingLabel:self.signatureLabel];
        self.signatureLabel.font = [self signatureFontWithSize:24.0];
        [self addSubview:self.signatureLabel];

        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.38];
        shadow.shadowBlurRadius = 10.0;
        shadow.shadowOffset = NSMakeSize(0, -1);
        self.signatureLabel.shadow = shadow;
    }
    return self;
}

- (void)applyConfig:(MirrorConfig *)config {
    self.currentConfig = config;
    self.signatureLabel.stringValue = config.signature ?: @"";
    self.signatureLabel.textColor = config.signatureColor;
    self.signatureLabel.font = [self signatureFontWithSize:config.signatureFontSize];

    NSSize targetSize = [self preferredSize];
    self.frame = NSMakeRect(self.frame.origin.x, self.frame.origin.y, targetSize.width, targetSize.height);
    [self setNeedsLayout:YES];
}

- (NSSize)preferredSize {
    CGFloat maxWidth = 420.0;
    CGFloat horizontalPadding = 18.0;
    CGFloat verticalPadding = 8.0;
    NSDictionary *signatureAttrs = @{ NSFontAttributeName: self.signatureLabel.font ?: [NSFont systemFontOfSize:22.0] };
    NSRect signatureRect = [self.signatureLabel.stringValue boundingRectWithSize:NSMakeSize(maxWidth, CGFLOAT_MAX)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                      attributes:signatureAttrs];

    CGFloat width = ceil(signatureRect.size.width) + (horizontalPadding * 2.0) + 6.0;
    CGFloat height = ceil(signatureRect.size.height) + (verticalPadding * 2.0);
    width = MAX(width, 120.0);
    height = MAX(height, 52.0);
    return NSMakeSize(width, height);
}

- (void)layout {
    [super layout];
    CGFloat horizontalPadding = 18.0;
    CGFloat verticalPadding = 8.0;
    CGFloat width = MAX(self.bounds.size.width - (horizontalPadding * 2.0), 0.0);
    CGFloat height = MAX(self.bounds.size.height - (verticalPadding * 2.0), self.signatureLabel.font.pointSize * 1.2);
    self.signatureLabel.frame = NSMakeRect(horizontalPadding, verticalPadding, width, height);
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    if (self.dragTrackingArea != nil) {
        [self removeTrackingArea:self.dragTrackingArea];
    }

    self.dragTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                         options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect
                                                           owner:self
                                                        userInfo:nil];
    [self addTrackingArea:self.dragTrackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    [[NSCursor openHandCursor] push];
}

- (void)mouseExited:(NSEvent *)event {
    [NSCursor pop];
}

- (void)mouseDown:(NSEvent *)event {
    if (event.clickCount == 2) {
        if (self.onOpenSettings != nil) {
            self.onOpenSettings();
        }
        return;
    }

    [[NSCursor closedHandCursor] push];
    self.dragStartLocation = [NSEvent mouseLocation];
    if (self.window != nil) {
        self.dragStartOrigin = self.window.frame.origin;
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (self.window == nil) {
        return;
    }

    NSPoint currentLocation = [NSEvent mouseLocation];
    NSPoint newOrigin = NSMakePoint(
        self.dragStartOrigin.x + (currentLocation.x - self.dragStartLocation.x),
        self.dragStartOrigin.y + (currentLocation.y - self.dragStartLocation.y)
    );
    [self.window setFrameOrigin:newOrigin];

    if (self.onDragMove != nil) {
        self.onDragMove(newOrigin);
    }
}

- (void)mouseUp:(NSEvent *)event {
    [NSCursor pop];
    [[NSCursor openHandCursor] push];
}

@end

@interface MirrorPanel : NSPanel
@property (nonatomic, strong) MirrorContentView *mirrorView;
- (instancetype)initWithSize:(CGFloat)size;
- (void)moveToBottomRightWithSize:(CGFloat)size;
- (void)resizeToSizePreservingCenter:(CGFloat)size;
@end

@interface TextOverlayPanel : NSPanel
@property (nonatomic, strong) TextOverlayView *overlayView;
- (instancetype)initWithConfig:(MirrorConfig *)config;
- (void)applyConfig:(MirrorConfig *)config;
- (void)moveNearMirrorFrame:(NSRect)mirrorFrame;
@end

@implementation MirrorPanel

- (instancetype)initWithSize:(CGFloat)size {
    self = [super initWithContentRect:NSMakeRect(0, 0, size, size)
                            styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (self) {
        self.floatingPanel = YES;
        self.level = NSStatusWindowLevel;
        self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorStationary;
        self.backgroundColor = NSColor.clearColor;
        self.opaque = NO;
        self.hasShadow = YES;
        self.hidesOnDeactivate = NO;
        self.ignoresMouseEvents = NO;

        self.mirrorView = [[MirrorContentView alloc] initWithFrame:NSMakeRect(0, 0, size, size)];
        self.contentView = self.mirrorView;
        [self setContentSize:NSMakeSize(size, size)];
        self.movableByWindowBackground = YES;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (void)moveToBottomRightWithSize:(CGFloat)size {
    NSScreen *screen = NSScreen.mainScreen ?: NSScreen.screens.firstObject;
    if (screen == nil) {
        return;
    }

    NSRect visibleFrame = screen.visibleFrame;
    CGFloat margin = 24.0;
    NSPoint origin = NSMakePoint(NSMaxX(visibleFrame) - size - margin, NSMinY(visibleFrame) + margin);
    [self setFrame:NSMakeRect(origin.x, origin.y, size, size) display:YES animate:YES];
}

- (void)resizeToSizePreservingCenter:(CGFloat)size {
    NSRect currentFrame = self.frame;
    NSPoint center = NSMakePoint(NSMidX(currentFrame), NSMidY(currentFrame));
    NSRect nextFrame = NSMakeRect(center.x - (size / 2.0), center.y - (size / 2.0), size, size);

    NSScreen *screen = self.screen ?: NSScreen.mainScreen ?: NSScreen.screens.firstObject;
    if (screen != nil) {
        NSRect visibleFrame = screen.visibleFrame;
        nextFrame.origin.x = MIN(MAX(nextFrame.origin.x, NSMinX(visibleFrame)), NSMaxX(visibleFrame) - size);
        nextFrame.origin.y = MIN(MAX(nextFrame.origin.y, NSMinY(visibleFrame)), NSMaxY(visibleFrame) - size);
    }

    [self setFrame:nextFrame display:YES animate:NO];
}

@end

@implementation TextOverlayPanel

- (instancetype)initWithConfig:(MirrorConfig *)config {
    NSSize initialSize = NSMakeSize(220.0, 90.0);
    self = [super initWithContentRect:NSMakeRect(0, 0, initialSize.width, initialSize.height)
                            styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (self) {
        self.floatingPanel = YES;
        self.level = NSStatusWindowLevel;
        self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorStationary;
        self.backgroundColor = NSColor.clearColor;
        self.opaque = NO;
        self.hasShadow = NO;
        self.hidesOnDeactivate = NO;

        self.overlayView = [[TextOverlayView alloc] initWithFrame:NSMakeRect(0, 0, initialSize.width, initialSize.height)];
        self.contentView = self.overlayView;
        [self applyConfig:config];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (void)applyConfig:(MirrorConfig *)config {
    [self.overlayView applyConfig:config];
    NSSize size = [self.overlayView preferredSize];
    [self setContentSize:size];
    self.overlayView.frame = NSMakeRect(0, 0, size.width, size.height);
}

- (void)moveNearMirrorFrame:(NSRect)mirrorFrame {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat spacing = 12.0;
    NSPoint origin = NSMakePoint(NSMidX(mirrorFrame) - (width / 2.0), NSMinY(mirrorFrame) - height - spacing);
    [self setFrame:NSMakeRect(origin.x, origin.y, width, height) display:YES];
}

@end

@interface SettingsWindowController : NSWindowController
@property (nonatomic, copy) void (^onConfigChange)(MirrorConfig *config);
@property (nonatomic, copy) void (^onResetPosition)(void);
- (instancetype)initWithConfig:(MirrorConfig *)config;
- (void)syncFromConfig:(MirrorConfig *)config;
@end

@interface SettingsWindowController ()
@property (nonatomic, strong) MirrorConfig *sourceConfig;
@property (nonatomic, strong) MirrorConfig *config;
@property (nonatomic, strong) NSTextField *signatureField;
@property (nonatomic, strong) NSColorWell *signatureColorWell;
@property (nonatomic, strong) NSSlider *signatureFontSlider;
@property (nonatomic, strong) NSTextField *signatureFontValueLabel;
@property (nonatomic, strong) NSTextField *signaturePreviewLabel;
@property (nonatomic, strong) NSSlider *sizeSlider;
@property (nonatomic, strong) NSTextField *sizeValueLabel;
@property (nonatomic, strong) NSPopUpButton *shapePopup;
@property (nonatomic, strong) NSVisualEffectView *rootVisualEffectView;
@end

@interface SettingsWindow : NSWindow
@end

@implementation SettingsWindow

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    NSEventModifierFlags modifiers = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    if (modifiers == NSEventModifierFlagControl) {
        NSString *characters = event.charactersIgnoringModifiers.lowercaseString;
        SEL action = NULL;
        if ([characters isEqualToString:@"c"]) {
            action = @selector(copy:);
        } else if ([characters isEqualToString:@"v"]) {
            action = @selector(paste:);
        } else if ([characters isEqualToString:@"x"]) {
            action = @selector(cut:);
        } else if ([characters isEqualToString:@"a"]) {
            action = @selector(selectAll:);
        }

        if (action != NULL) {
            return [NSApp sendAction:action to:nil from:self];
        }
    }

    return [super performKeyEquivalent:event];
}

@end

@implementation SettingsWindowController

- (instancetype)initWithConfig:(MirrorConfig *)config {
    NSWindow *window = [[SettingsWindow alloc] initWithContentRect:NSMakeRect(0, 0, 470, 470)
                                                         styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
    self = [super initWithWindow:window];
    if (self) {
        _sourceConfig = config;
        _config = [config copy];
        [self setupWindow];
        [self buildUI];
        [self applyCurrentConfigToControls];
    }
    return self;
}

- (void)syncFromConfig:(MirrorConfig *)config {
    self.sourceConfig = config;
    self.config = [config copy];
    if (self.isWindowLoaded) {
        [self applyCurrentConfigToControls];
    }
}

- (void)setupWindow {
    self.window.title = @"Mirror Settings";
    [self.window center];
    self.window.releasedWhenClosed = NO;
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
}

- (NSFont *)signaturePreviewFontWithSize:(CGFloat)size {
    return [NSFont fontWithName:@"Snell Roundhand Bold" size:size] ?: ([NSFont fontWithName:@"Didot" size:size] ?: [NSFont systemFontOfSize:size weight:NSFontWeightMedium]);
}

- (void)buildUI {
    NSView *contentView = self.window.contentView;
    if (contentView == nil) {
        return;
    }

    self.rootVisualEffectView = [[NSVisualEffectView alloc] initWithFrame:contentView.bounds];
    self.rootVisualEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rootVisualEffectView.material = NSVisualEffectMaterialSidebar;
    self.rootVisualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    self.rootVisualEffectView.state = NSVisualEffectStateActive;
    [contentView addSubview:self.rootVisualEffectView];

    NSTextField *eyebrowLabel = [NSTextField labelWithString:@"CAMERA MIRROR"];
    eyebrowLabel.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightBold];
    eyebrowLabel.textColor = [NSColor colorWithCalibratedRed:0.88 green:0.41 blue:0.47 alpha:1.0];

    NSTextField *titleLabel = [NSTextField labelWithString:@"Overlay & Mirror Settings"];
    titleLabel.font = [NSFont systemFontOfSize:24.0 weight:NSFontWeightSemibold];
    titleLabel.textColor = NSColor.labelColor;

    NSTextField *introLabel = [NSTextField wrappingLabelWithString:@"Double-click the watermark text or hover over the camera to reopen this panel. Changes update instantly."];
    introLabel.font = [NSFont systemFontOfSize:13.0];
    introLabel.textColor = NSColor.secondaryLabelColor;
    introLabel.alignment = NSTextAlignmentCenter;
    introLabel.maximumNumberOfLines = 0;
    introLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [[introLabel.widthAnchor constraintLessThanOrEqualToConstant:360.0] setActive:YES];

    self.signatureField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.signatureField.placeholderString = @"Signature";
    self.signatureColorWell = [[NSColorWell alloc] initWithFrame:NSZeroRect];
    self.signatureFontSlider = [[NSSlider alloc] initWithFrame:NSZeroRect];
    self.signatureFontSlider.minValue = 16.0;
    self.signatureFontSlider.maxValue = 64.0;
    self.signatureFontValueLabel = [NSTextField labelWithString:@""];
    self.signaturePreviewLabel = [NSTextField wrappingLabelWithString:@""];
    self.sizeSlider = [[NSSlider alloc] initWithFrame:NSZeroRect];
    self.sizeSlider.minValue = 220.0;
    self.sizeSlider.maxValue = 420.0;
    self.shapePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [self.shapePopup addItemsWithTitles:@[@"Circle", @"Rounded Square", @"Soft Square"]];
    self.sizeValueLabel = [NSTextField labelWithString:@""];
    self.sizeValueLabel.font = [NSFont monospacedDigitSystemFontOfSize:12.0 weight:NSFontWeightMedium];
    self.sizeValueLabel.textColor = NSColor.secondaryLabelColor;
    self.signatureFontValueLabel.font = [NSFont monospacedDigitSystemFontOfSize:12.0 weight:NSFontWeightMedium];
    self.signatureFontValueLabel.textColor = NSColor.secondaryLabelColor;
    self.signaturePreviewLabel.alignment = NSTextAlignmentCenter;
    self.signaturePreviewLabel.maximumNumberOfLines = 0;
    self.signaturePreviewLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self configureColorWell:self.signatureColorWell];

    [self.signatureField setTarget:self];
    [self.signatureField setAction:@selector(handleDraftChange:)];
    [self.signatureColorWell setTarget:self];
    [self.signatureColorWell setAction:@selector(handleDraftChange:)];
    [self.signatureFontSlider setTarget:self];
    [self.signatureFontSlider setAction:@selector(handleDraftChange:)];
    [self.sizeSlider setTarget:self];
    [self.sizeSlider setAction:@selector(handleDraftChange:)];
    [self.shapePopup setTarget:self];
    [self.shapePopup setAction:@selector(handleDraftChange:)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:self.signatureField];

    NSButton *resetButton = [NSButton buttonWithTitle:@"Reset Mirror Position" target:self action:@selector(resetPosition:)];
    resetButton.bezelStyle = NSBezelStyleRounded;
    resetButton.contentTintColor = [NSColor colorWithCalibratedRed:0.88 green:0.41 blue:0.47 alpha:1.0];

    NSButton *closeButton = [NSButton buttonWithTitle:@"Hide Panel" target:self action:@selector(hideWindow:)];
    closeButton.bezelStyle = NSBezelStyleRounded;

    NSButton *applyButton = [NSButton buttonWithTitle:@"Apply" target:self action:@selector(applyChanges:)];
    applyButton.bezelStyle = NSBezelStyleRounded;
    applyButton.contentTintColor = [NSColor colorWithCalibratedRed:0.25 green:0.53 blue:0.98 alpha:1.0];

    NSStackView *stack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.spacing = 18.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.edgeInsets = NSEdgeInsetsMake(24.0, 24.0, 24.0, 24.0);

    [stack addArrangedSubview:eyebrowLabel];
    [stack addArrangedSubview:titleLabel];
    [stack addArrangedSubview:introLabel];
    [stack addArrangedSubview:[self sectionCardWithTitle:@"Signature" rows:@[
        [self labeledRowWithTitle:@"Signature" control:self.signatureField]
    ]]];
    [stack addArrangedSubview:[self sectionCardWithTitle:@"Styling" rows:@[
        [self textStyleRowWithTitle:@"Signature style" colorWell:self.signatureColorWell slider:self.signatureFontSlider valueLabel:self.signatureFontValueLabel]
    ]]];
    [stack addArrangedSubview:[self previewCard]];
    [stack addArrangedSubview:[self sectionCardWithTitle:@"Mirror Shape" rows:@[
        [self labeledRowWithTitle:@"Frame shape" control:self.shapePopup],
        [self sizeRow]
    ]]];
    [stack addArrangedSubview:[self buttonRowWithViews:@[resetButton, closeButton, applyButton]]];

    [self.rootVisualEffectView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.rootVisualEffectView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [self.rootVisualEffectView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [self.rootVisualEffectView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [self.rootVisualEffectView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:self.rootVisualEffectView.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:self.rootVisualEffectView.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:self.rootVisualEffectView.topAnchor constant:12.0],
        [stack.bottomAnchor constraintEqualToAnchor:self.rootVisualEffectView.bottomAnchor]
    ]];
}

- (NSView *)labeledRowWithTitle:(NSString *)title control:(NSView *)control {
    NSTextField *titleLabel = [NSTextField labelWithString:title];
    titleLabel.font = [NSFont systemFontOfSize:13.0 weight:NSFontWeightMedium];
    [titleLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

    control.translatesAutoresizingMaskIntoConstraints = NO;
    [[control.widthAnchor constraintGreaterThanOrEqualToConstant:180.0] setActive:YES];

    NSStackView *row = [NSStackView stackViewWithViews:@[titleLabel, control]];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.alignment = NSLayoutAttributeCenterY;
    row.spacing = 12.0;
    return row;
}

- (void)configureColorWell:(NSColorWell *)colorWell {
    colorWell.translatesAutoresizingMaskIntoConstraints = NO;
    colorWell.controlSize = NSControlSizeSmall;
    [[colorWell.widthAnchor constraintEqualToConstant:34.0] setActive:YES];
    [[colorWell.heightAnchor constraintEqualToConstant:22.0] setActive:YES];
}

- (NSView *)textStyleRowWithTitle:(NSString *)title colorWell:(NSColorWell *)colorWell slider:(NSSlider *)slider valueLabel:(NSTextField *)valueLabel {
    NSTextField *titleLabel = [NSTextField labelWithString:title];
    titleLabel.font = [NSFont systemFontOfSize:13.0 weight:NSFontWeightMedium];
    [titleLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

    slider.translatesAutoresizingMaskIntoConstraints = NO;
    [[slider.widthAnchor constraintGreaterThanOrEqualToConstant:150.0] setActive:YES];
    [valueLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSStackView *controls = [NSStackView stackViewWithViews:@[colorWell, slider, valueLabel]];
    controls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    controls.alignment = NSLayoutAttributeCenterY;
    controls.spacing = 10.0;

    NSStackView *row = [NSStackView stackViewWithViews:@[titleLabel, controls]];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.alignment = NSLayoutAttributeCenterY;
    row.spacing = 12.0;
    return row;
}

- (NSView *)sectionCardWithTitle:(NSString *)title rows:(NSArray<NSView *> *)rows {
    NSVisualEffectView *card = [[NSVisualEffectView alloc] initWithFrame:NSZeroRect];
    card.material = NSVisualEffectMaterialHUDWindow;
    card.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    card.state = NSVisualEffectStateActive;
    card.wantsLayer = YES;
    card.layer.cornerRadius = 18.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.08].CGColor;

    NSTextField *titleLabel = [NSTextField labelWithString:title];
    titleLabel.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightBold];
    titleLabel.textColor = [NSColor colorWithCalibratedRed:0.88 green:0.41 blue:0.47 alpha:1.0];

    NSStackView *stack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.spacing = 12.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.edgeInsets = NSEdgeInsetsMake(16.0, 16.0, 16.0, 16.0);
    [stack addArrangedSubview:titleLabel];
    for (NSView *row in rows) {
        [stack addArrangedSubview:row];
    }

    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];

    return card;
}

- (NSView *)previewCard {
    NSVisualEffectView *card = [[NSVisualEffectView alloc] initWithFrame:NSZeroRect];
    card.material = NSVisualEffectMaterialHUDWindow;
    card.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    card.state = NSVisualEffectStateActive;
    card.wantsLayer = YES;
    card.layer.cornerRadius = 18.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.08].CGColor;

    NSTextField *titleLabel = [NSTextField labelWithString:@"Preview"];
    titleLabel.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightBold];
    titleLabel.textColor = [NSColor colorWithCalibratedRed:0.88 green:0.41 blue:0.47 alpha:1.0];

    NSView *previewSurface = [[NSView alloc] initWithFrame:NSZeroRect];
    previewSurface.translatesAutoresizingMaskIntoConstraints = NO;
    previewSurface.wantsLayer = YES;
    previewSurface.layer.cornerRadius = 14.0;
    previewSurface.layer.backgroundColor = [NSColor colorWithWhite:0.08 alpha:0.6].CGColor;

    [previewSurface addSubview:self.signaturePreviewLabel];

    NSStackView *stack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.spacing = 12.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.edgeInsets = NSEdgeInsetsMake(16.0, 16.0, 16.0, 16.0);
    [stack addArrangedSubview:titleLabel];
    [stack addArrangedSubview:previewSurface];

    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [previewSurface.heightAnchor constraintEqualToConstant:88.0],
        [self.signaturePreviewLabel.leadingAnchor constraintEqualToAnchor:previewSurface.leadingAnchor constant:16.0],
        [self.signaturePreviewLabel.trailingAnchor constraintEqualToAnchor:previewSurface.trailingAnchor constant:-16.0],
        [self.signaturePreviewLabel.centerYAnchor constraintEqualToAnchor:previewSurface.centerYAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];

    return card;
}

- (NSView *)sizeRow {
    NSTextField *label = [NSTextField labelWithString:@"Circle size"];
    label.font = [NSFont systemFontOfSize:13.0 weight:NSFontWeightMedium];
    [label setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.sizeValueLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSStackView *controls = [NSStackView stackViewWithViews:@[self.sizeSlider, self.sizeValueLabel]];
    controls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    controls.spacing = 12.0;

    NSStackView *row = [NSStackView stackViewWithViews:@[label, controls]];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing = 12.0;
    return row;
}

- (NSView *)buttonRowWithViews:(NSArray<NSView *> *)views {
    NSView *spacer = [[NSView alloc] initWithFrame:NSZeroRect];
    NSMutableArray<NSView *> *arranged = [NSMutableArray arrayWithObject:spacer];
    [arranged addObjectsFromArray:views];
    NSStackView *row = [NSStackView stackViewWithViews:arranged];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing = 10.0;
    return row;
}

- (void)applyCurrentConfigToControls {
    self.signatureField.stringValue = self.config.signature ?: @"";
    self.signatureColorWell.color = self.config.signatureColor;
    self.signatureFontSlider.doubleValue = self.config.signatureFontSize;
    self.sizeSlider.doubleValue = self.config.diameter;
    [self.shapePopup selectItemAtIndex:self.config.shape];
    self.signatureFontValueLabel.stringValue = [NSString stringWithFormat:@"%d pt", (int)round(self.config.signatureFontSize)];
    self.sizeValueLabel.stringValue = [NSString stringWithFormat:@"%d px", (int)self.config.diameter];
    [self updatePreview];
}

- (void)handleDraftChange:(id)sender {
    self.config.signature = self.signatureField.stringValue ?: @"";
    self.config.signatureColor = self.signatureColorWell.color;
    self.config.signatureFontSize = round(self.signatureFontSlider.doubleValue);
    self.config.diameter = round(self.sizeSlider.doubleValue);
    self.config.shape = (MirrorShape)self.shapePopup.indexOfSelectedItem;
    self.signatureFontValueLabel.stringValue = [NSString stringWithFormat:@"%d pt", (int)self.config.signatureFontSize];
    self.sizeValueLabel.stringValue = [NSString stringWithFormat:@"%d px", (int)self.config.diameter];
    [self updatePreview];
}

- (void)updatePreview {
    self.signaturePreviewLabel.stringValue = self.config.signature.length > 0 ? self.config.signature : @"Preview your signature";
    self.signaturePreviewLabel.textColor = self.config.signatureColor;
    self.signaturePreviewLabel.font = [self signaturePreviewFontWithSize:self.config.signatureFontSize];
}

- (void)applyChanges:(id)sender {
    self.sourceConfig.signature = self.config.signature;
    self.sourceConfig.signatureColor = self.config.signatureColor;
    self.sourceConfig.signatureFontSize = self.config.signatureFontSize;
    self.sourceConfig.diameter = self.config.diameter;
    self.sourceConfig.shape = self.config.shape;
    self.sourceConfig.mirrorOriginX = self.config.mirrorOriginX;
    self.sourceConfig.mirrorOriginY = self.config.mirrorOriginY;
    self.sourceConfig.overlayOriginX = self.config.overlayOriginX;
    self.sourceConfig.overlayOriginY = self.config.overlayOriginY;

    [SettingsStore saveConfig:self.sourceConfig];
    if (self.onConfigChange != nil) {
        self.onConfigChange(self.sourceConfig);
    }
}

- (void)textDidChange:(NSNotification *)notification {
    [self handleDraftChange:notification.object];
}

- (void)resetPosition:(id)sender {
    if (self.onResetPosition != nil) {
        self.onResetPosition();
    }
}

- (void)hideWindow:(id)sender {
    [self.window orderOut:nil];
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) MirrorConfig *config;
@property (nonatomic, strong) MirrorPanel *mirrorPanel;
@property (nonatomic, strong) TextOverlayPanel *textOverlayPanel;
@property (nonatomic, strong) SettingsWindowController *settingsWindowController;
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.config = [SettingsStore loadConfig];

    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [self buildMenu];
    [self buildStatusItem];
    [self createMirrorPanel];
    [self createTextOverlayPanel];
    [self createSettingsWindow];

    [self.mirrorPanel orderFrontRegardless];
    [self.textOverlayPanel orderFrontRegardless];
    [self.settingsWindowController showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositionMirror) name:NSApplicationDidChangeScreenParametersNotification object:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO;
}

- (void)buildMenu {
    NSMenu *mainMenu = [[NSMenu alloc] init];

    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];

    NSMenu *appMenu = [[NSMenu alloc] init];
    NSMenuItem *settingsItem = [[NSMenuItem alloc] initWithTitle:@"Settings" action:@selector(showSettings) keyEquivalent:@","];
    [settingsItem setTarget:self];
    [appMenu addItem:settingsItem];
    [appMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit Camera Mirror" action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItem:quitItem];
    appMenuItem.submenu = appMenu;

    [NSApp setMainMenu:mainMenu];
}

- (void)buildStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"Mirror";

    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *showItem = [[NSMenuItem alloc] initWithTitle:@"Open Settings" action:@selector(showSettings) keyEquivalent:@""];
    showItem.target = self;
    [menu addItem:showItem];

    NSMenuItem *hideItem = [[NSMenuItem alloc] initWithTitle:@"Hide Settings" action:@selector(hideSettings) keyEquivalent:@""];
    hideItem.target = self;
    [menu addItem:hideItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit Camera Mirror" action:@selector(terminate:) keyEquivalent:@""];
    [menu addItem:quitItem];

    self.statusItem.menu = menu;
}

- (void)createMirrorPanel {
    self.mirrorPanel = [[MirrorPanel alloc] initWithSize:self.config.diameter];
    [self.mirrorPanel.mirrorView applyConfig:self.config];

    if (self.config.mirrorOriginX != CGFLOAT_MAX && self.config.mirrorOriginY != CGFLOAT_MAX) {
        [self.mirrorPanel setFrameOrigin:NSMakePoint(self.config.mirrorOriginX, self.config.mirrorOriginY)];
    } else {
        [self.mirrorPanel moveToBottomRightWithSize:self.config.diameter];
        self.config.mirrorOriginX = self.mirrorPanel.frame.origin.x;
        self.config.mirrorOriginY = self.mirrorPanel.frame.origin.y;
        [SettingsStore saveConfig:self.config];
    }
}

- (void)createTextOverlayPanel {
    self.textOverlayPanel = [[TextOverlayPanel alloc] initWithConfig:self.config];

    if (self.config.overlayOriginX != CGFLOAT_MAX && self.config.overlayOriginY != CGFLOAT_MAX) {
        [self.textOverlayPanel setFrameOrigin:NSMakePoint(self.config.overlayOriginX, self.config.overlayOriginY)];
    } else {
        [self.textOverlayPanel moveNearMirrorFrame:self.mirrorPanel.frame];
        self.config.overlayOriginX = self.textOverlayPanel.frame.origin.x;
        self.config.overlayOriginY = self.textOverlayPanel.frame.origin.y;
        [SettingsStore saveConfig:self.config];
    }
}

- (void)createSettingsWindow {
    self.settingsWindowController = [[SettingsWindowController alloc] initWithConfig:self.config];

    __weak typeof(self) weakSelf = self;
    self.settingsWindowController.onConfigChange = ^(MirrorConfig *updatedConfig) {
        weakSelf.config = updatedConfig;
        [weakSelf.mirrorPanel resizeToSizePreservingCenter:updatedConfig.diameter];
        [weakSelf.mirrorPanel setContentSize:NSMakeSize(updatedConfig.diameter, updatedConfig.diameter)];
        weakSelf.mirrorPanel.contentView.frame = NSMakeRect(0, 0, updatedConfig.diameter, updatedConfig.diameter);
        weakSelf.mirrorPanel.mirrorView.frame = NSMakeRect(0, 0, updatedConfig.diameter, updatedConfig.diameter);
        weakSelf.mirrorPanel.mirrorView.needsLayout = YES;
        [weakSelf.mirrorPanel.contentView setNeedsDisplay:YES];
        [weakSelf.mirrorPanel.mirrorView applyConfig:updatedConfig];
        [weakSelf.textOverlayPanel applyConfig:updatedConfig];
        if (updatedConfig.overlayOriginX != CGFLOAT_MAX && updatedConfig.overlayOriginY != CGFLOAT_MAX) {
            [weakSelf.textOverlayPanel setFrameOrigin:NSMakePoint(updatedConfig.overlayOriginX, updatedConfig.overlayOriginY)];
        }
        [weakSelf.mirrorPanel orderFrontRegardless];
        [weakSelf.textOverlayPanel orderFrontRegardless];
    };

    self.settingsWindowController.onResetPosition = ^{
        [weakSelf repositionMirror];
    };

    self.mirrorPanel.mirrorView.onToggleSettings = ^{
        if (weakSelf.settingsWindowController.window.isVisible) {
            [weakSelf hideSettings];
        } else {
            [weakSelf showSettings];
        }
    };

    self.mirrorPanel.mirrorView.onQuit = ^{
        [NSApp terminate:nil];
    };

    self.mirrorPanel.mirrorView.onDragMove = ^(NSPoint origin) {
        weakSelf.config.mirrorOriginX = origin.x;
        weakSelf.config.mirrorOriginY = origin.y;
        [SettingsStore saveConfig:weakSelf.config];
    };

    self.textOverlayPanel.overlayView.onDragMove = ^(NSPoint origin) {
        weakSelf.config.overlayOriginX = origin.x;
        weakSelf.config.overlayOriginY = origin.y;
        [SettingsStore saveConfig:weakSelf.config];
    };

    self.textOverlayPanel.overlayView.onOpenSettings = ^{
        [weakSelf showSettings];
    };
}

- (void)showSettings {
    [self.settingsWindowController syncFromConfig:self.config];
    [self.settingsWindowController showWindow:nil];
    [self.settingsWindowController.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)hideSettings {
    [self.settingsWindowController.window orderOut:nil];
}

- (void)repositionMirror {
    [self.mirrorPanel moveToBottomRightWithSize:self.config.diameter];
    self.config.mirrorOriginX = self.mirrorPanel.frame.origin.x;
    self.config.mirrorOriginY = self.mirrorPanel.frame.origin.y;
    [SettingsStore saveConfig:self.config];
    [self.mirrorPanel orderFrontRegardless];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
