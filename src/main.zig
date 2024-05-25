const std = @import("std");

const KILOBYTES = 1024;
const MAX_STORY_SIZE = 512 * KILOBYTES;

const StoryLoadError = error{
    IncompleteRead,
};

const ZMachine = struct {
    memory: [MAX_STORY_SIZE]u8, // 512KB is maximum supported memory for last Z-Machine (v8)

    fn load_story(self: *ZMachine, path_to_story: []const u8) !void {
        var zork_file = try std.fs.cwd().openFile(path_to_story, .{});
        defer zork_file.close();

        const expected_file_size = try zork_file.getEndPos();
        const bytes_read = try zork_file.readAll(self.memory[0..expected_file_size]);
        if (bytes_read != expected_file_size) {
            std.debug.print("Failed to read entire file: {s}. {d} of {d} bytes read.\n", .{ path_to_story, bytes_read, expected_file_size });
            return StoryLoadError.IncompleteRead;
        }
    }

    //
    // Z-Machine Header
    //
    fn story_version(self: *ZMachine) u8 {
        return self.memory[0x0];
    }

    fn story_length(self: *ZMachine) u16 {
        return read_word(self, 0x1A);
    }

    fn story_checksum(self: *ZMachine) u16 {
        return read_word(self, 0x1C);
    }

    fn high_mem_base(self: *ZMachine) u16 {
        return read_word(self, 0x4);
    }

    fn static_mem_base(self: *ZMachine) u16 {
        return read_word(self, 0xE);
    }

    fn initial_pc(self: *ZMachine) u16 {
        return read_word(self, 0x6);
    }

    fn dict_loc(self: *ZMachine) u16 {
        return read_word(self, 0x8);
    }

    fn obj_loc(self: *ZMachine) u16 {
        return read_word(self, 0xA);
    }

    fn globals_loc(self: *ZMachine) u16 {
        return read_word(self, 0xC);
    }

    fn abbrev_loc(self: *ZMachine) u16 {
        return read_word(self, 0x18);
    }

    //
    // Memory Read/Write
    //
    fn read_word(self: *ZMachine, addr: u16) u16 {
        // Z-Machine is Big Endian. Need to swap around the bytes on Little Endian systems.
        return @as(u16, self.memory[addr]) << 8 | @as(u16, self.memory[addr + 1]);
    }
};

var vm = ZMachine{ .memory = undefined };

pub fn main() !void {
    const zork_path = "rom/zork2-r63-s860811.z3";

    try vm.load_story(zork_path);

    std.debug.print("Z-Machine Information:\n", .{});
    std.debug.print("\tStory Version: {d}\n", .{vm.story_version()});
    std.debug.print("\tStory Length: {d}\n", .{vm.story_length()});
    std.debug.print("\tStory Checksum: 0x{X:0>4}\n", .{vm.story_checksum()});
    std.debug.print("\tHigh Memory Base: 0x{X:0>4}\n", .{vm.high_mem_base()});
    std.debug.print("\tStatic Memory Base: 0x{X:0>4}\n", .{vm.static_mem_base()});
    std.debug.print("\tInitial PC: 0x{X:0>4}\n", .{vm.initial_pc()});
    std.debug.print("\tDictionary Location: 0x{X:0>4}\n", .{vm.dict_loc()});
    std.debug.print("\tObject Table Location: 0x{X:0>4}\n", .{vm.obj_loc()});
    std.debug.print("\tGlobals Location: 0x{X:0>4}\n", .{vm.globals_loc()});
    std.debug.print("\tAbbreviation Table Location: 0x{X:0>4}\n", .{vm.abbrev_loc()});
}
