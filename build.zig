const std = @import("std");
const libxml2 = @import("libxml2.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_xml2_c = b.dependency("libxml2", .{
        .target = target,
        .optimize = optimize,
    });

    const xml2 = b.addStaticLibrary(.{
        .name = "xml2",
        .target = target,
        .optimize = optimize,
    });

    const opts = user_options(b);
    const is_windows = is_target_windows(target);
    const flags = try libxml2.compile_flags(b, opts, is_windows);
    defer b.allocator.free(flags);

    // C files
    xml2.addCSourceFiles(.{
        .root = dep_xml2_c.path(""),
        .files = libxml2.srcs,
        .flags = flags,
    });

    xml2.addIncludePath(dep_xml2_c.path("include"));
    xml2.addIncludePath(b.path(libxml2.override_include_dir));
    if (is_windows) {
        xml2.addIncludePath(b.path("override/config/win32"));
        xml2.linkSystemLibrary("ws2_32");
    } else {
        xml2.addIncludePath(b.path("override/config/posix"));
    }
    xml2.linkLibC();

    xml2.installHeadersDirectory(dep_xml2_c.path("include/libxml"), "libxml", .{});
    xml2.installHeadersDirectory(
        b.path(libxml2.override_include_dir),
        "",
        .{ .include_extensions = &.{"xmlversion.h"} },
    );
    b.installArtifact(xml2);

    // todo: uncomment when zig-zlib is updated
    // const z = zlib.create(b, target, optimize);
    // z.link(xml2_with_libs.step, .{});

    const static_binding_test = b.addTest(.{
        .root_source_file = b.path("test/basic.zig"),
        .optimize = optimize,
    });

    const run_static_binding_test = b.addRunArtifact(static_binding_test);
    static_binding_test.linkLibrary(xml2);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&xml2.step);
    test_step.dependOn(&run_static_binding_test.step);
}

fn user_options(b: *std.Build) libxml2.Options {
    return libxml2.Options{
        .c14n = b.option(bool, "c14n", "Canonical XML 1.0 support") orelse true,
        .catalog = b.option(bool, "catalog", "XML Catalogs support") orelse true,
        .debug = b.option(bool, "debug", "Debugging module and shell") orelse true,
        .ftp = b.option(bool, "ftp", "FTP support") orelse false,
        .history = b.option(bool, "history", "History support for shell") orelse true,
        .html = b.option(bool, "html", "HTML parser") orelse true,
        .iconv = b.option(bool, "iconv", "iconv support") orelse false, // TODO: not supported yet
        .icu = b.option(bool, "icu", "ICU support") orelse false,
        .iso8859x = b.option(bool, "iso8859x", "ISO-8859-X support if no iconv") orelse true,
        .legacy = b.option(bool, "legacy", "Maximum ABI compatibility") orelse false,
        .mem_debug = b.option(bool, "mem_debug", "Runtime debugging module") orelse false,
        .minimum = b.option(bool, "minimum", "build a minimally sized library") orelse true,
        .output = b.option(bool, "output", "Serialization support") orelse true,
        .pattern = b.option(bool, "pattern", "xmlPattern selection interface") orelse true,
        .push = b.option(bool, "push", "push parser interfaces") orelse true,
        .reader = b.option(bool, "reader", "xmlReader parsing interface") orelse true,
        .regexp = b.option(bool, "regexp", "Regular expressions support") orelse true,
        .run_debug = b.option(bool, "run_debug", "Memory debugging module") orelse false,
        .sax1 = b.option(bool, "sax1", "Older SAX1 interface") orelse true,
        .schemas = b.option(bool, "schemas", "XML Schemas 1.0 and RELAX NG support") orelse true,
        .schematron = b.option(bool, "schematron", "Schematron support") orelse true,
        .thread = b.option(bool, "thread", "Multithreading support") orelse true,
        .thread_alloc = b.option(bool, "thread_alloc", "per-thread malloc hooks") orelse false,
        .tree = b.option(bool, "tree", "DOM like tree manipulation APIs") orelse true,
        .valid = b.option(bool, "valid", "DTD validation support") orelse true,
        .writer = b.option(bool, "writer", "xmlWriter serialization interface") orelse true,
        .xinclude = b.option(bool, "xinclude", "XInclude 1.0 support") orelse true,
        .xpath = b.option(bool, "xpath", "XPath 1.0 support") orelse true,
        .xptr = b.option(bool, "xptr", "XPointer support") orelse true,
        .xptr_locs = b.option(bool, "xptr_locs", "XPointer ranges and points") orelse false,
        .modules = b.option(bool, "modules", "Dynamic modules support") orelse true,
        .lzma = b.option(bool, "lzma", "LZMA support") orelse false, // TODO: not supported yet
        .zlib = b.option(bool, "zlib", "ZLIB support") orelse false, // TODO: not supported yet
    };
}

fn is_target_windows(target: std.Build.ResolvedTarget) bool {
    if (target.query.os_tag) |tag| {
        return tag == .windows;
    }
    return false;
}
