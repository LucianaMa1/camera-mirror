#import <AppKit/AppKit.h>

static void drawRoundedRect(NSRect rect, CGFloat radius, NSColor *color) {
    [color setFill];
    [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius] fill];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "Usage: generate_icon <output-png-path>\n");
            return 1;
        }

        NSString *outputPath = [NSString stringWithUTF8String:argv[1]];
        CGFloat size = 1024.0;
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];

        [image lockFocus];

        NSRect canvas = NSMakeRect(0, 0, size, size);

        NSGradient *background = [[NSGradient alloc] initWithColors:@[
            [NSColor colorWithCalibratedRed:0.98 green:0.87 blue:0.79 alpha:1.0],
            [NSColor colorWithCalibratedRed:0.95 green:0.67 blue:0.61 alpha:1.0]
        ]];
        [background drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:canvas xRadius:220 yRadius:220] angle:90];

        NSBezierPath *glow = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(180, 560, 680, 280)];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.16] setFill];
        [glow fill];

        NSRect mirrorRect = NSMakeRect(230, 170, 560, 560);
        NSBezierPath *mirror = [NSBezierPath bezierPathWithOvalInRect:mirrorRect];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] setFill];
        [mirror fill];

        NSBezierPath *mirrorInner = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(mirrorRect, 36, 36)];
        NSGradient *mirrorGradient = [[NSGradient alloc] initWithColors:@[
            [NSColor colorWithCalibratedRed:0.83 green:0.93 blue:0.99 alpha:1.0],
            [NSColor colorWithCalibratedRed:0.67 green:0.83 blue:0.97 alpha:1.0]
        ]];
        [mirrorGradient drawInBezierPath:mirrorInner angle:90];

        NSBezierPath *screenHighlight = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(330, 500, 270, 110) xRadius:55 yRadius:55];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.23] setFill];
        [screenHighlight fill];

        NSBezierPath *head = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(418, 400, 180, 180)];
        [[NSColor colorWithCalibratedRed:0.34 green:0.30 blue:0.34 alpha:0.92] setFill];
        [head fill];

        NSBezierPath *body = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(360, 255, 300, 210) xRadius:130 yRadius:130];
        [[NSColor colorWithCalibratedRed:0.34 green:0.30 blue:0.34 alpha:0.92] setFill];
        [body fill];

        NSBezierPath *hatMain = [NSBezierPath bezierPath];
        [hatMain moveToPoint:NSMakePoint(420, 605)];
        [hatMain lineToPoint:NSMakePoint(555, 790)];
        [hatMain lineToPoint:NSMakePoint(685, 615)];
        [hatMain closePath];
        [[NSColor colorWithCalibratedRed:0.86 green:0.15 blue:0.20 alpha:1.0] setFill];
        [hatMain fill];

        drawRoundedRect(NSMakeRect(395, 585, 315, 48), 24, [NSColor colorWithCalibratedWhite:1.0 alpha:1.0]);

        NSBezierPath *pom = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(530, 775, 64, 64)];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
        [pom fill];

        NSBezierPath *watermark = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(655, 180, 190, 82) xRadius:28 yRadius:28];
        [[NSColor colorWithCalibratedRed:0.17 green:0.16 blue:0.20 alpha:0.92] setFill];
        [watermark fill];

        NSDictionary *titleAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:44 weight:NSFontWeightSemibold],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:1.0 alpha:0.96]
        };
        [@"REC" drawAtPoint:NSMakePoint(694, 200) withAttributes:titleAttrs];

        NSBezierPath *recordDot = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(666, 208, 18, 18)];
        [[NSColor colorWithCalibratedRed:0.99 green:0.34 blue:0.34 alpha:1.0] setFill];
        [recordDot fill];

        [image unlockFocus];

        CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
        NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        BOOL success = [pngData writeToFile:outputPath atomically:YES];
        return success ? 0 : 1;
    }
}
