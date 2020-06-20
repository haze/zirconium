const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("zirconium", "src/main.zig");
    lib.addPackage(.{ .name = "network", .path = "../zig-network/network.zig" });
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.addPackage(.{ .name = "network", .path = "../zig-network/network.zig" });
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
