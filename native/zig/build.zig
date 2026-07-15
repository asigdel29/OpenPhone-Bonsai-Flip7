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
    const persistence = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/openphone_persistence.zig"), .target = target, .optimize = optimize,
    }) });
    const run_persistence = b.addRunArtifact(persistence);
    const router = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/openphone_router.zig"), .target = target, .optimize = optimize,
    }) });
    const run_router = b.addRunArtifact(router);
    const bonsai = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/bonsai_admission.zig"), .target = target, .optimize = optimize,
    }) });
    const run_bonsai = b.addRunArtifact(bonsai);
    const computer_use = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/computer_use_guard.zig"), .target = target, .optimize = optimize,
    }) });
    const run_computer_use = b.addRunArtifact(computer_use);
    const consent = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/openrouter_consent.zig"), .target = target, .optimize = optimize,
    }) });
    const run_consent = b.addRunArtifact(consent);
    const hermes = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/hermes_sandbox.zig"), .target = target, .optimize = optimize,
    }) });
    const run_hermes = b.addRunArtifact(hermes);
    const supervision = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/runtime_supervision.zig"), .target = target, .optimize = optimize,
    }) });
    const run_supervision = b.addRunArtifact(supervision);
    const broker = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/broker_contract.zig"), .target = target, .optimize = optimize,
    }) });
    const run_broker = b.addRunArtifact(broker);
    const test_step = b.step("test", "Run the native ABI contract test");
    test_step.dependOn(&run.step);
    test_step.dependOn(&run_core.step);
    test_step.dependOn(&run_persistence.step);
    test_step.dependOn(&run_router.step);
    test_step.dependOn(&run_bonsai.step);
    test_step.dependOn(&run_computer_use.step);
    test_step.dependOn(&run_consent.step);
    test_step.dependOn(&run_hermes.step);
    test_step.dependOn(&run_supervision.step);
    test_step.dependOn(&run_broker.step);
}
