const std = @import("std");
const objc = @import("objc");
const CapyWindowDelegate = @This();
const internal = @import("../../internal.zig");
const backend = @import("backend.zig");
const lib = @import("../../capy.zig");

var class: ?objc.Class = null;

const capyDataPointerIvarName = "capy_data_pointer";

pub fn getObjcClass() objc.Class {
    if (class) |notNull| {
        return notNull;
    } else {
        class = objc.allocateClassPair(objc.getClass("NSObject").?, "CapyWindowDelegate").?;
        defer objc.registerClassPair(class.?);

        _ = class.?.addIvar(capyDataPointerIvarName);

        _ = class.?.addMethod("windowDidResize:", struct {
            fn a(self: objc.c.id, sel: objc.c.SEL, notification: objc.c.id) callconv(.C) void {
                _ = sel;
                const window = objc.Object.fromId(notification).msgSend(objc.Object, "object", .{});

                // Probably all kinds of wrong.
                var data: *backend.EventUserData = undefined;
                _ = objc.c.object_getInstanceVariable(self, capyDataPointerIvarName, @ptrCast(&data));
                backend.Window.onResize(backend.GuiWidget{
                    .object = window,
                    .data = data,
                });
            }
        }.a) catch unreachable;

        return class.?;
    }
}

pub fn makeInstance(data: *backend.EventUserData) !objc.Object {
    const delegate = getObjcClass().msgSend(objc.Object, "alloc", .{})
        .msgSend(objc.Object, "init", .{});
    // Probably all kinds of wrong.
    var ivarData: **backend.EventUserData = undefined;
    _ = objc.c.object_getInstanceVariable(delegate.value, capyDataPointerIvarName, @ptrCast(&ivarData));
    ivarData.* = data;
    return delegate;
}

pub fn deinit(self: CapyWindowDelegate) void {
    self.class.disposeClassPair();
}
