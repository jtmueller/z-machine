const std = @import("std");
const consts = @import("consts.zig");
const Allocator = std.mem.Allocator;

const KILOBYTES = 1024;
const MAX_STORY_SIZE = 512 * KILOBYTES;

pub const StoryLoadError = error{
    IncompleteRead,
};

pub const ZMachine = struct {
    allocator: Allocator,
    memory: []u8,
    stack: std.ArrayList(u16),
    /// Z-Machine Header
    story_version: u8,
    /// Program Counter
    pc: u16,

    const Self = @This();

    pub fn init(path_to_story: []const u8, allocator: Allocator) !Self {
        var story_file = try std.fs.cwd().openFile(path_to_story, .{});
        defer story_file.close();

        const expected_file_size = try story_file.getEndPos();
        const memory = try allocator.alloc(u8, expected_file_size);
        const bytes_read = try story_file.readAll(memory);
        if (bytes_read != expected_file_size) {
            std.debug.print(
                "Failed to read entire file: {s}. {d} of {d} bytes read.\n",
                .{ path_to_story, bytes_read, expected_file_size },
            );
            return StoryLoadError.IncompleteRead;
        }

        const stack = std.ArrayList(u16).init(allocator);

        return .{
            .allocator = allocator,
            .memory = memory,
            .stack = stack,
            .story_version = memory[consts.HEADER],
            .pc = read_word(memory, consts.INITIAL_PC),
        };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();
        self.allocator.free(self.memory);
    }

    pub fn story_length(self: *Self) u32 {
        // Up to v3, the story length this value multiplied by 2.
        // See "packed addresses" in the specification for more information.
        return @as(u32, read_word(self.memory, consts.STORY_LENGTH)) * 2;
    }

    pub fn story_checksum(self: *Self) u16 {
        return read_word(self.memory, consts.STORY_CHECKSUM);
    }

    pub fn high_mem_base(self: *Self) u16 {
        return read_word(self.memory, consts.HIGH_MEM_BASE);
    }

    pub fn static_mem_base(self: *Self) u16 {
        return read_word(self.memory, consts.STATIC_MEM_BASE);
    }

    pub fn dict_loc(self: *Self) u16 {
        return read_word(self.memory, consts.DICT_LOC);
    }

    pub fn obj_loc(self: *Self) u16 {
        return read_word(self.memory, consts.OBJ_LOC);
    }

    pub fn globals_loc(self: *Self) u16 {
        return read_word(self.memory, consts.GLOBALS_LOC);
    }

    pub fn abbrev_loc(self: *Self) u16 {
        return read_word(self.memory, consts.ABBREV_LOC);
    }

    //
    // Memory Read/Write
    //
    fn read_word(memory: []u8, addr: u16) u16 {
        // Z-Machine is Big Endian. Need to swap around the bytes on Little Endian systems.
        return std.mem.readInt(u16, memory[addr..][0..2], .big);
    }

    //
    // Debug Helpers
    //
    pub fn print_memory(self: *Self, start_addr: u16, lines: u8) void {
        const BYTES_PER_LINE = 16;

        const aligned_start = start_addr & 0xFFF0;
        const aligned_end = (start_addr + BYTES_PER_LINE * lines) & 0xFFF0;

        var cur_addr = aligned_start;
        std.debug.print("        00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n", .{});
        std.debug.print("-------------------------------------------------------\n", .{});

        while (cur_addr < aligned_end) {
            std.debug.print("0x{X:0>4}: ", .{cur_addr});
            const next_addr = cur_addr + BYTES_PER_LINE;
            const line = self.memory[cur_addr..next_addr];
            for (line) |byte| {
                std.debug.print("{X:0>2} ", .{byte});
            }

            std.debug.print("\n", .{});
            cur_addr = next_addr;
        }
        std.debug.print("\n", .{});
    }
};
