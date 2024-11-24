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
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
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
        var vm = try ZMachine.init(file, allocator);
        defer vm.deinit(allocator);

        std.debug.print("\nZ-Machine Information:\n", .{});
        std.debug.print("\tStory Version: {d}\n", .{vm.story_version()});
        std.debug.print("\tStory Length: {d}KB (max address: 0x{X:0>8})\n", .{ vm.story_length() / KILOBYTES, vm.story_length() - 1 });
        std.debug.print("\tStory Checksum: 0x{X:0>4}\n", .{vm.story_checksum()});
        std.debug.print("\tHigh Memory Base: 0x{X:0>4}\n", .{vm.high_mem_base()});
        std.debug.print("\tStatic Memory Base: 0x{X:0>4}\n", .{vm.static_mem_base()});
        std.debug.print("\tInitial PC: 0x{X:0>4}\n", .{vm.initial_pc()});
        std.debug.print("\tDictionary Location: 0x{X:0>4}\n", .{vm.dict_loc()});
        std.debug.print("\tObject Table Location: 0x{X:0>4}\n", .{vm.obj_loc()});
        std.debug.print("\tGlobals Location: 0x{X:0>4}\n", .{vm.globals_loc()});
        std.debug.print("\tAbbreviation Table Location: 0x{X:0>4}\n\n", .{vm.abbrev_loc()});

        return vm.print_memory(vm.dict_loc(), 12);
    }

    return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
}
