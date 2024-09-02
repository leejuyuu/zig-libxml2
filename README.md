# libxml2 Built with Zig

This repository contains Zig code for building libxml2 using Zig.
This allows other projects that use the Zig build system to easily
consume this library, cross-compile it, etc.

**Why?** Using the Zig build system makes it much easier to cross-compile
a library, even if you aren't using the Zig programming language. See
[Maintain it with Zig](https://kristoff.it/blog/maintain-it-with-zig/)
for some more information.

This library currently hardcodes the libxml2 version (latest as of writing
this but unlikely to remain that way for long). In the future, I'd like to
allow users to pass in a custom libxml2 directory, and it'd be really cool to
setup some sort of Github Action to check for new versions and try to pull
it in. Maybe one day.

## Usage

While we all eagerly await the [Zig Package Manager](https://github.com/ziglang/zig/issues/943),
the recommended way to use this is via git submodules or just embedding
this into your repository.

Run the following command to add the source of this repo to `build.zig.zon`.

```sh
zig fetch --save <url of source tar ball>
```

Add the following lines to your `build.zig`

```zig
pub fn build(b: *std.build.Builder) !void {
    // ...

    const xml2 = b.dependency("libxml2", .{
        .target = target,
        .optimize = optimize,

        // Put build options here
        .xptr_locs = true,
    });

    exe.linkLibrary(xml2.artifact("xml2"));

    // ...
}
```

This package does not provide any Zig-native APIs to access the underlying
C library. This is by design, the focus of this repository is only to enable
building the underlying library using the Zig build system. Therefore, to
use the library, import the headers and use the C API:

```zig
const c = @cImport({
    @cInclude("libxml/xmlreader.h");
});

// ... do stuff with `c`
```

### Other Dependencies

Some features require other libraries. In the example above, we disabled
those features. For example, if you set `.zlib = true`, then zlib must
be available.

In this scenario, you can find and use a zlib build such as
[zig-zlib](https://github.com/mattnite/zig-zlib) as normal. When that
library is also added to the project, it adds its include paths and
linking information to the build, so libxml2 can be built with zlib support.
