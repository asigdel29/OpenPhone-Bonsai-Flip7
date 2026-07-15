const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const abi = b.addStaticLibrary(.{ .name = "openphone_zig_abi", .root_module = b.createModule(.{
        .root_source_file = b.path("src/openphone_abi.zig"), .target = target, .optimize = optimize,
    }) });
    b.installArtifact(abi);

    const contract = b.addExecutable(.{ .name = "openphone_zig_abi_contract", .target = target, .optimize = optimize });
    contract.addCSourceFile(.{ .file = b.path("tests/abi_contract.c"), .flags = &.{ "-std=c11" } });
    contract.linkLibrary(abi);
    const run = b.addRunArtifact(contract);
    const core_contract = b.addExecutable(.{ .name = "openphone_zig_core_contract", .target = target, .optimize = optimize });
    core_contract.addCSourceFile(.{ .file = b.path("tests/core_contract.c"), .flags = &.{ "-std=c11" } });
    core_contract.linkLibrary(abi);
    const run_core = b.addRunArtifact(core_contract);
    const test_step = b.step("test", "Run the native ABI contract test");
    test_step.dependOn(&run.step);
    test_step.dependOn(&run_core.step);
}
