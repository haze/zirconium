const std = @import("std");
const mem = std.mem;
const net = @import("network");
const io = std.io;
pub const Command = @import("command.zig").Command;

const io_mode = .evented;

pub const Client = struct {
    const InitOptions = struct {
        user: []const u8,
        real_name: []const u8,
        nick: ?[]const u8 = null,

        stdin_is_client: bool = false,
    };

    allocator: *mem.Allocator,
    server: net.EndPoint,
    options: InitOptions,

    connected_reader: ?std.io.Reader(net.Socket, std.os.RecvFromError, net.Socket.receive),
    connected_writer: ?std.io.Writer(net.Socket, net.Socket.Error, net.Socket.send),

    pub fn initEndpoint(allocator: *mem.Allocator, server: net.EndPoint, options: InitOptions) Client {
        return Client{
            .allocator = allocator,
            .server = server,
            .options = options,

            .connected_reader = null,
            .connected_writer = null,
        };
    }

    pub fn initHost(allocator: *mem.Allocator, server: []const u8, port: u16, options: InitOptions) !Client {
        const list = try net.getEndpointList(allocator, server, port);
        defer list.deinit();

        if (list.endpoints.len == 0) return error.UnknownHostName;
        return Client.initEndpoint(allocator, list.endpoints[0], options);
    }

    fn stdinput(self: *Client) void {
        var stdin = std.io.getStdIn().reader();
        while (true) {
            var msg_buf: [512]u8 = undefined;
            if (stdin.readUntilDelimiterOrEof(&msg_buf, '\n') catch |e| {
                std.log.err(.irc, "{}", .{e});
                continue;
            }) |line| {
                if (self.connected_writer) |writer| {
                    writer.writeAll(line) catch |e| {
                        std.log.err(.irc, "{}", .{e});
                        continue;
                    };
                    writer.writeAll("\n") catch |e| {
                        std.log.err(.irc, "{}", .{e});
                        continue;
                    };
                    std.debug.warn("Wrote '{}'\n", .{line});
                }
            }
        }
    }

    pub fn connect(self: *Client) !void {
        // open connection
        var socket = try net.Socket.create(@as(net.AddressFamily, self.server.address), .tcp);
        try socket.connect(self.server);

        self.connected_reader = socket.inStream();
        self.connected_writer = socket.outStream();
        if (std.io.is_async and self.options.stdin_is_client) {
            _ = async self.stdinput();
        }
        try self.send_user(.{
            .first = self.options.user,
            .second = "0",
            .third = "*",
            .fourth = self.options.real_name,
        });
        if (self.options.nick) |nick| {
            try self.send_nick(.{
                .first = nick,
            });
        }
        while (true) {
            // irc messages are limited to 512 bytes
            const raw_line = self.connected_reader.?.readUntilDelimiterAlloc(self.allocator, '\n', 512) catch |err| {
                switch (err) {
                    error.EndOfStream => break,
                    else => return err,
                }
            };
            defer self.allocator.free(raw_line);
            const line = mem.trimRight(u8, raw_line, "\r\n");
            std.debug.warn("{}\n", .{line});
            if (Client.parseCommand(line)) |cmd| {
                try self.dispatchEvents(cmd);
            }
        }
    }

    fn dispatchEvents(self: *Client, command: ParsedMessage) !void {
        // respond to all pings
        switch (command.command) {
            .ping => |s| try self.send_pong(.{ .first = s.first }),
            else => {},
        }
    }

    // TODO(haze): support tags
    const ParsedMessage = struct {
        command: Command,
        server: ?[]const u8,
    };

    fn parseCommand(line: []const u8) ?ParsedMessage {
        var offset: u9 = 1;
        if (line[0] == ':') {
            if (mem.indexOfScalar(u8, line[offset..], ' ')) |server_end_pos| {
                const server = line[offset .. server_end_pos + 1];
                offset = @intCast(u9, server_end_pos + 2);
                return ParsedMessage{
                    .server = server,
                    .command = Command.parse(line[offset..]) orelse return null,
                };
            }
        } else {
            return ParsedMessage{
                .server = null,
                .command = Command.parse(line[0..]) orelse return null,
            };
        }
        return null;
    }

    fn send_user(self: *Client, command: Command.USER) !void {
        return self.send(.{ .user = command });
    }

    fn send_pong(self: *Client, command: Command.PING) !void {
        return self.send(.{ .pong = command });
    }

    fn send_nick(self: *Client, command: Command.NICK) !void {
        return self.send(.{ .nick = command });
    }

    fn send(self: *Client, command: Command) !void {
        if (self.connected_writer) |writer| {
            std.debug.warn("Sending '{}'\n", .{command});
            return writer.print("{}\n", .{command});
        } else {
            std.debug.warn("Attempting to send without attached writer", .{});
        }
    }

    pub fn deinit(self: *Client) void {
        self.* = undefined;
    }
};

test "decls" {
    std.meta.refAllDecls(Command);
    std.meta.refAllDecls(Client);
}

test "client" {
    _ = try std.os.windows.WSAStartup(2, 2);
    defer std.os.windows.WSACleanup() catch @panic("Error during cleanup");

    std.debug.warn("\n{}\n", .{std.io.is_async});
    var client = try Client.initHost(std.testing.allocator, "irc.rizon.io", 6667, .{
        .user = "zirconium",
        .real_name = "zirconium v0.1",
        .nick = "zirc_user",
        .stdin_is_client = true,
    });
    defer client.deinit();
    std.debug.warn("\n", .{});
    try client.connect();
}
