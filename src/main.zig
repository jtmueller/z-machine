const std = @import("std");
const clap = @import("clap");
const ZMachine = @import("zmachine.zig").ZMachine;

const VERSION = "0.0.1";
const KILOBYTES = 1024;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`
    const params = comptime clap.parseParamsComptime(
        \\-f, --file <str>       Load and run the indicated z-machine story file.
        \\-h, --help             Display this help and exit.
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return;
    };
    defer res.deinit();

    std.debug.print("\nZig-Machine (v{s})\n", .{VERSION});

    if (res.args.help != 0) {
        std.debug.print("\n", .{});
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }

    if (res.args.file) |file| {
        res.deinit();

        var vm = try ZMachine.init(file, allocator);
        defer vm.deinit();

        std.debug.print("\nZ-Machine Information:\n", .{});
        std.debug.print("\tStory Version: {d}\n", .{vm.headers.story_version()});
        std.debug.print("\tStory Serial: {s}\n", .{vm.headers.serial()});
        std.debug.print("\tStory Length: {d}KB (max address: 0x{X:0>8})\n", .{ vm.headers.story_length() / KILOBYTES, vm.headers.story_length() - 1 });
        std.debug.print("\tStory Checksum: 0x{X:0>4}\n", .{vm.headers.story_checksum()});
        std.debug.print("\tHigh Memory Base: 0x{X:0>4}\n", .{vm.headers.high_mem_base()});
        std.debug.print("\tStatic Memory Base: 0x{X:0>4}\n", .{vm.headers.static_mem_base()});
        std.debug.print("\tProgram Counter: 0x{X:0>4}\n", .{vm.pc});
        std.debug.print("\tDictionary Location: 0x{X:0>4}\n", .{vm.headers.dict_loc()});
        std.debug.print("\tObject Table Location: 0x{X:0>4}\n", .{vm.headers.obj_loc()});
        std.debug.print("\tGlobals Location: 0x{X:0>4}\n", .{vm.headers.globals_loc()});
        std.debug.print("\tAbbreviation Table Location: 0x{X:0>4}\n\n", .{vm.headers.abbrev_loc()});

        return vm.print_memory(vm.headers.dict_loc(), 12);
    }

    return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
}
