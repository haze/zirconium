const std = @import("std");
const irc = @import("irc");

pub const io_mode = .evented;

pub fn main() anyerror!void {
    std.debug.warn("\n{}\n", .{std.io.is_async});
    var client = try irc.Client.initHost(std.testing.allocator, "irc.rizon.io", 6667, .{
        .user = "zirconium",
        .real_name = "zirconium v0.1",
        .nick = "zirc_user",
        .stdin_is_client = true,
    });
    defer client.deinit();
    std.debug.warn("\n", .{});
    try client.connect();
}
