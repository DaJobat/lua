const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const liblua = buildLibLua(b, target, optimize);

    b.installArtifact(liblua);

    const exe = b.addExecutable(.{
        .name = "lua",
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.linkLibrary(liblua);
    exe.addCSourceFile("lua.c", &.{});

    var exe_step = b.step("exe", "emit lua executable");
    var emit_exe = b.addInstallArtifact(exe);
    exe_step.dependOn(&emit_exe.step);
}

pub fn buildLibLua(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const lua = b.addStaticLibrary(.{
        .name = "liblua",
        .target = target,
        .optimize = optimize,
    });

    for (PresetModules.get(.core)) |module| {
        lua.addCSourceFile(std.mem.concat(b.allocator, u8, &.{ @tagName(module), ".c" }) catch @panic("OOM"), &.{});
    }
    for (PresetModules.get(.lib)) |module| {
        lua.addCSourceFile(std.mem.concat(b.allocator, u8, &.{ @tagName(module), ".c" }) catch @panic("OOM"), &.{});
    }

    lua.linkLibC();

    return lua;
}

const LuaPreset = enum {
    core,
    lib,
};

const PresetModules = std.EnumArray(LuaPreset, []const LuaModule).init(.{
    .core = &.{ .lapi, .lcode, .lctype, .ldebug, .ldo, .ldump, .lfunc, .lgc, .llex, .lmem, .lobject, .lopcodes, .lparser, .lstate, .lstring, .ltable, .ltm, .lundump, .lvm, .lzio },
    .lib = &.{ .lauxlib, .lbaselib, .lcorolib, .ldblib, .liolib, .lmathlib, .loadlib, .loslib, .lstrlib, .ltablib, .lutf8lib, .linit },
});

const LuaModule = enum { lapi, lauxlib, lbaselib, lcode, lcorolib, lctype, ldblib, ldebug, ldo, ldump, lfunc, lgc, linit, liolib, llex, lmathlib, lmem, loadlib, lobject, lopcodes, loslib, lparser, lstate, lstring, lstrlib, ltable, ltablib, ltm, lua, luac, lundump, lutf8lib, lvm, lzio };
