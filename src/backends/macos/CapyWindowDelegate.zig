const std = @import("std");
const objc = @import("objc");
const CapyWindowDelegate = @This();
const internal = @import("../../internal.zig");
const backend = @import("backend.zig");
const lib = @import("../../capy.zig");

var class: ?objc.Class = null;

pub fn getObjcClass() objc.Class {
    if (class) |notNull| {
        return notNull;
    } else {
        class = objc.allocateClassPair(objc.getClass("NSObject").?, "CapyWindowDelegate").?;
        defer objc.registerClassPair(class.?);

        _ = class.?.addMethod("windowDidResize:", struct {
            fn a(self: objc.c.id, sel: objc.c.SEL, notification: objc.c.id) callconv(.C) void {
                _ = self;
                _ = sel;
                const window = objc.Object.fromId(notification).msgSend(objc.Object, "object", .{});
                // WRONG! .data needs to be passed on from the data stored with the window. That's the whole point.
                // I don't know how to without closures.
                backend.Window.onResize(backend.GuiWidget{
                    .object = window,
                    .data = lib.internal.scratch_allocator.create(backend.EventUserData) catch std.debug.panic("Please fix.", .{}),
                });
            }
        }.a) catch unreachable;

        return class.?;
    }
}

pub fn makeInstance() !objc.Object {
    const delegate = getObjcClass().msgSend(objc.Object, "alloc", .{})
        .msgSend(objc.Object, "init", .{});
    return delegate;
}

pub fn deinit(self: CapyWindowDelegate) void {
    self.class.disposeClassPair();
}
