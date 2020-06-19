const std = @import("std");
const mem = std.mem;

pub const Command = union(enum) {
    pub fn parse(line: []const u8) ?Command {
        if (mem.indexOfScalar(u8, line, ' ')) |commad_end_idx| {
            const command = line[0..commad_end_idx];
            inline for (std.meta.fields(Command)) |field| {
                comptime var name_idx: usize = 0;
                var mask: bool = true;
                inline for (field.name) |char| {
                    if (mask) {
                        if (name_idx == command.len - 1) {
                            return @unionInit(Command, field.name, @field(field.field_type, "parse")(line[field.name.len + 1 ..]) orelse return null);
                        } else {
                            const matches = std.ascii.toUpper(char) == command[name_idx];
                            mask = mask and matches;
                            if (matches) {
                                name_idx += 1;
                            }
                        }
                    }
                }
            }
        }
        return null;
    }

    const None = struct {
        fn parse(line: []const u8) ?None {
            return None{};
        }
    };
    const Single = struct {
        first: []const u8,
        fn parse(line: []const u8) ?Single {
            return Single{
                .first = line,
            };
        }
    };
    const SingleAndMore = struct {
        first: []const u8,
        rest: ?[]const u8 = null,

        fn parse(line: []const u8) ?SingleAndMore {
            if (line[0] == ':') {
                return SingleAndMore{
                    .first = line[1..],
                };
            } else {
                if (mem.indexOfScalar(u8, line, ' ')) |first_arg_idx| {
                    return SingleAndMore{
                        .first = line[0..first_arg_idx],
                        .rest = line[first_arg_idx + 1 ..],
                    };
                } else {
                    return SingleAndMore{
                        .first = line,
                    };
                }
            }
        }
    };
    const Double = struct {
        first: []const u8,
        second: []const u8,
        fn parse(line: []const u8) ?Double {
            if (mem.indexOfScalar(u8, line, ' ')) |first_arg_idx| {
                return Double{
                    .first = line[0..first_arg_idx],
                    .second = line[first_arg_idx + 1 ..],
                };
            }
            return null;
        }
    };
    const MaybeSingle = struct {
        first: ?[]const u8,
        fn parse(line: []const u8) ?MaybeSingle {
            return MaybeSingle{
                .first = if (line.len > 0) line else null,
            };
        }
    };
    const Triple = struct {
        first: []const u8,
        second: []const u8,
        third: []const u8,
        fn parse(line: []const u8) ?Triple {
            var offset: usize = 0;
            if (mem.indexOfScalar(u8, line[offset..], ' ')) |first_arg_idx| {
                const first = line[offset..first_arg_idx];
                offset = first_arg_idx + 2;
                if (mem.indexOfScalar(u8, line[offset..], ' ')) |second_arg_idx| {
                    const second = line[offset..second_arg_idx];
                    offset = second_arg_idx + 2;
                    return Triple{
                        .first = first,
                        .second = second,
                        .third = line[offset..],
                    };
                }
            }
            return null;
        }
    };
    const Hexa = struct {
        first: []const u8,
        second: []const u8,
        third: []const u8,
        fourth: []const u8,
        fifth: []const u8,
        sixth: []const u8,
        seventh: []const u8,
        fn parse(line: []const u8) ?Hexa {
            var offset: usize = 0;
            if (mem.indexOfScalar(u8, line[offset..], ' ')) |first_arg_idx| {
                const first = line[offset..first_arg_idx];
                offset = first_arg_idx + 2;
                if (mem.indexOfScalar(u8, line[offset..], ' ')) |second_arg_idx| {
                    const second = line[offset..second_arg_idx];
                    offset = second_arg_idx + 2;
                    if (mem.indexOfScalar(u8, line[offset..], ' ')) |third_arg_idx| {
                        const third = line[offset..third_arg_idx];
                        offset = third_arg_idx + 2;
                        if (mem.indexOfScalar(u8, line[offset..], ' ')) |fourth_arg_idx| {
                            const fourth = line[offset..fourth_arg_idx];
                            offset = third_arg_idx + 2;
                            if (mem.indexOfScalar(u8, line[offset..], ' ')) |fifth_arg_idx| {
                                const fifth = line[offset..fifth_arg_idx];
                                offset = third_arg_idx + 2;
                                if (mem.indexOfScalar(u8, line[offset..], ' ')) |sixth_arg_idx| {
                                    const sixth = line[offset..sixth_arg_idx];
                                    offset = third_arg_idx + 2;
                                    return Hexa{
                                        .first = first,
                                        .second = second,
                                        .third = third,
                                        .fourth = fourth,
                                        .fifth = fifth,
                                        .sixth = sixth,
                                        .seventh = line[offset..],
                                    };
                                }
                            }
                        }
                    }
                }
            }
            return null;
        }
    };
    const Quad = struct {
        first: []const u8,
        second: []const u8,
        third: []const u8,
        fourth: []const u8,
        fn parse(line: []const u8) ?Quad {
            var offset: usize = 0;
            if (mem.indexOfScalar(u8, line[offset..], ' ')) |first_arg_idx| {
                const first = line[offset..first_arg_idx];
                offset = first_arg_idx + 2;
                if (mem.indexOfScalar(u8, line[offset..], ' ')) |second_arg_idx| {
                    const second = line[offset..second_arg_idx];
                    offset = second_arg_idx + 2;
                    if (mem.indexOfScalar(u8, line[offset..], ' ')) |third_arg_idx| {
                        const third = line[offset..third_arg_idx];
                        offset = third_arg_idx + 2;
                        return Quad{
                            .first = first,
                            .second = second,
                            .third = third,
                            .fourth = line[offset..],
                        };
                    }
                }
            }
            return null;
        }
    };

    pub fn format(
        self: Command,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        out_stream: var,
    ) !void {
        for (@tagName(std.meta.activeTag(self))) |char| {
            try std.fmt.format(out_stream, "{c}", .{std.ascii.toUpper(char)});
        }
        try std.fmt.format(out_stream, " ", .{});
        switch (self) {
            .userhost, .userip, .wallops, .away, .err, .ison, .join, .knock, .pass, .setname => |s| try std.fmt.format(out_stream, "{}", .{s.first}),
            .squery, .squit, .privmsg, .oper, .notice, .mode, .kill, .kick, .invite, .cprivmsg, .cnotice => |d| try std.fmt.format(out_stream, "{} {}", .{ d.first, d.second }),
            .whowas, .whois, .topic, .summon, .stats, .pong, .ping, .part, .nick, .connect => |sam| {
                try std.fmt.format(out_stream, "{}", .{sam.first});
                if (sam.rest) |rest| {
                    try std.fmt.format(out_stream, " :{}", .{rest});
                }
            },
            .user => |q| try std.fmt.format(out_stream, "{} {} {} :{}", .{ q.first, q.second, q.third, q.fourth }),
            .server, .encap => |t| {},
            else => {},
        }
        // try std.fmt.format(out_stream, "{}", .{});
    }

    pub const AWAY = Single;
    pub const CNOTICE = Double;
    pub const CPRIVMSG = Double;
    pub const CONNECT = SingleAndMore;
    pub const DIE = None;
    pub const ENCAP = Triple;
    pub const ERROR = Single;
    pub const HELP = None;
    pub const INFO = MaybeSingle;
    pub const INVITE = Double;
    pub const ISON = Single;
    pub const JOIN = Single;
    pub const KICK = Double;
    pub const KILL = Double;
    pub const KNOCK = Single;
    pub const LINKS = MaybeSingle;
    pub const LIST = MaybeSingle;
    pub const LUSERS = MaybeSingle;
    pub const MODE = Double;
    pub const MOTD = MaybeSingle;
    pub const NAMES = MaybeSingle;
    pub const NAMESX = None;
    pub const NICK = SingleAndMore;
    pub const NOTICE = Double;
    pub const OPER = Double;
    pub const PART = SingleAndMore;
    pub const PASS = Single;
    pub const PING = SingleAndMore;
    pub const PONG = SingleAndMore;
    pub const PRIVMSG = Double;
    pub const QUIT = MaybeSingle;
    pub const REHASH = None;
    pub const RESTART = None;
    pub const RULES = None;
    pub const SERVER = Triple;
    pub const SERVICE = Hexa;
    pub const SERVLIST = MaybeSingle;
    pub const SQUERY = Double;
    pub const SQUIT = Double;
    pub const SETNAME = Single;
    pub const SILENCE = MaybeSingle;
    pub const STATS = SingleAndMore;
    pub const SUMMON = SingleAndMore;
    pub const TIME = MaybeSingle;
    pub const TOPIC = SingleAndMore;
    pub const TRACE = MaybeSingle;
    pub const UHNAMES = None;
    pub const USER = Quad;
    pub const USERHOST = Single;
    pub const USERIP = Single;
    pub const USERS = MaybeSingle;
    pub const VERSION = MaybeSingle;
    pub const WALLOPS = Single;
    pub const WATCH = MaybeSingle;
    pub const WHO = MaybeSingle;
    pub const WHOIS = SingleAndMore;
    pub const WHOWAS = SingleAndMore;

    away: AWAY,
    cnotice: CNOTICE,
    cprivmsg: CPRIVMSG,
    connect: CONNECT,
    die: DIE,
    encap: ENCAP,
    err: ERROR,
    help: HELP,
    info: INFO,
    invite: INVITE,
    ison: ISON,
    join: JOIN,
    kick: KICK,
    kill: KILL,
    knock: KNOCK,
    links: LINKS,
    list: LIST,
    lusers: LUSERS,
    mode: MODE,
    mod: MOTD,
    names: NAMES,
    namesx: NAMESX,
    nick: NICK,
    notice: NOTICE,
    oper: OPER,
    part: PART,
    pass: PASS,
    ping: PING,
    pong: PONG,
    privmsg: PRIVMSG,
    quit: QUIT,
    rehash: REHASH,
    restart: RESTART,
    rules: RULES,
    server: SERVER,
    service: SERVICE,
    servlist: SERVLIST,
    squery: SQUERY,
    squit: SQUIT,
    setname: SETNAME,
    silence: SILENCE,
    stats: STATS,
    summon: SUMMON,
    time: TIME,
    topic: TOPIC,
    trace: TRACE,
    uhnames: UHNAMES,
    user: USER,
    userhost: USERHOST,
    userip: USERIP,
    users: USERS,
    version: VERSION,
    wallops: WALLOPS,
    watch: WATCH,
    who: WHO,
    whois: WHOIS,
    whowas: WHOWAS,
};
