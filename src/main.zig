const std = @import("std");
const ZMachine = @import("zmachine.zig").ZMachine;

const KILOBYTES = 1024;

pub fn main() !void {
    const story_path = "rom/zork2-r63-s860811.z3";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var vm = try ZMachine.init(story_path, allocator);
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

    vm.print_memory(vm.dict_loc(), 12);
}
