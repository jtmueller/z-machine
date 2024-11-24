const std = @import("std");
const Allocator = std.mem.Allocator;

const KILOBYTES = 1024;
const MAX_STORY_SIZE = 512 * KILOBYTES;

pub const StoryLoadError = error{
    IncompleteRead,
};

pub const ZMachine = struct {
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

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.memory);
    }

    /// Z-Machine Header
    pub fn story_version(self: *Self) u8 {
        return self.memory[0x0];
    }

    pub fn story_length(self: *Self) u32 {
        // Up to v3, the story length this value multiplied by 2.
        // See "packed addresses" in the specification for more information.
        return @as(u32, read_word(self, 0x1A)) * 2;
    }

    pub fn story_checksum(self: *Self) u16 {
        return read_word(self, 0x1C);
    }

    pub fn high_mem_base(self: *Self) u16 {
        return read_word(self, 0x4);
    }

    pub fn static_mem_base(self: *Self) u16 {
        return read_word(self, 0xE);
    }

    pub fn initial_pc(self: *Self) u16 {
        return read_word(self, 0x6);
    }

    pub fn dict_loc(self: *Self) u16 {
        return read_word(self, 0x8);
    }

    pub fn obj_loc(self: *Self) u16 {
        return read_word(self, 0xA);
    }

    pub fn globals_loc(self: *Self) u16 {
        return read_word(self, 0xC);
    }

    pub fn abbrev_loc(self: *Self) u16 {
        return read_word(self, 0x18);
    }

    //
    // Memory Read/Write
    //
    fn read_word(self: *Self, addr: u16) u16 {
        // Z-Machine is Big Endian. Need to swap around the bytes on Little Endian systems.
        return @as(u16, self.memory[addr]) << 8 | @as(u16, self.memory[addr + 1]);
    }

    //
    // Debug Helpers
    //
    pub fn print_memory(self: *Self, start_addr: u16, lines: u8) void {
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
