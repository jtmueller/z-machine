const std = @import("std");
const Allocator = std.mem.Allocator;

const KILOBYTES = 1024;
const MAX_STORY_SIZE = 512 * KILOBYTES;

const StoryLoadError = error{
    IncompleteRead,
};

const ZMachine = struct {
    memory: []u8,

    const Self = @This();

    pub fn init(path_to_story: []const u8, allocator: Allocator) !Self {
        var story_file = try std.fs.cwd().openFile(path_to_story, .{});
        defer story_file.close();

        const expected_file_size = try story_file.getEndPos();
        const memory = try allocator.alloc(u8, expected_file_size);
        const bytes_read = try story_file.readAll(memory);
        if (bytes_read != expected_file_size) {
            std.debug.print("Failed to read entire file: {s}. {d} of {d} bytes read.\n", .{ path_to_story, bytes_read, expected_file_size });
            return StoryLoadError.IncompleteRead;
        }
        return .{ .memory = memory };
    }

    fn deinit(self: *ZMachine, allocator: Allocator) void {
        allocator.free(self.memory);
    }

    /// Z-Machine Header
    fn story_version(self: *ZMachine) u8 {
        return self.memory[0x0];
    }

    fn story_length(self: *ZMachine) u32 {
        // Up to v3, the story length this value multiplied by 2.
        // See "packed addresses" in the specification for more information.
        return @as(u32, read_word(self, 0x1A)) * 2;
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

    //
    // Debug Helpers
    //
    fn print_memory(self: *ZMachine, start_addr: u16, lines: u8) void {
        const BYTES_PER_LINE = 16;

        const aligned_start = start_addr & 0xFFF0;
        const aligned_end = (start_addr + BYTES_PER_LINE * lines) & 0xFFF0;

        var curr_addr = aligned_start;
        std.debug.print("        00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n", .{});
        //std.debug.print("------------------------------------------------------\n", .{});
        while (curr_addr < aligned_end) {
            var curr_offset: u8 = 0;
            std.debug.print("0x{X:0>4}: ", .{curr_addr + curr_offset});
            while (curr_offset < BYTES_PER_LINE) {
                const curr_byte = self.memory[curr_addr + curr_offset];
                std.debug.print("{X:0>2} ", .{curr_byte});
                curr_offset += 1;
            }

            std.debug.print("\n", .{});
            curr_addr += BYTES_PER_LINE;
        }
        std.debug.print("\n", .{});
    }
};

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
