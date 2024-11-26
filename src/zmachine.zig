const std = @import("std");
const consts = @import("consts.zig");
const read_word = @import("utils.zig").read_word;
const Headers = @import("headers.zig").Headers;
const VariableSlots = @import("variables.zig").VariableSlots;
const Allocator = std.mem.Allocator;

const KILOBYTES = 1024;
const MAX_STORY_SIZE = 512 * KILOBYTES;

pub const StoryLoadError = error{
    IncompleteRead,
    UnsupportedStoryVersion,
};

pub const PackType = enum(u1) {
    routine,
    zstring,
};

pub const ZMachine = struct {
    allocator: Allocator,
    memory: []u8,
    headers: Headers,
    stack: std.ArrayList(u16),
    /// Global variables (240 of them)
    globals: VariableSlots,
    /// Local variables (15 of them)
    locals: VariableSlots,
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
        var headers = Headers.init(memory);

        if (headers.story_version() == 0) {
            return StoryLoadError.UnsupportedStoryVersion;
        }

        const globals_loc = headers.globals_loc();

        return .{
            .allocator = allocator,
            .memory = memory,
            .headers = headers,
            .stack = stack,
            .globals = VariableSlots.init_bytes(memory[globals_loc..][0..(240 * 2)]),
            .locals = try VariableSlots.init_size(15, allocator),
            .pc = headers.initial_pc(),
        };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();
        self.locals.deinit(self.allocator);
        self.allocator.free(self.memory);
    }

    fn unpack_addr(self: *Self, addr: u16, pack_type: PackType) u32 {
        switch (self.headers.story_version()) {
            1...3 => addr * 2,
            4, 5 => addr * 4,
            6, 7 => (addr * 4) +
                (8 * self.memory[if (pack_type == .routine) consts.ROUTINES_OFFSET else consts.ZSTRINGS_OFFSET]),
            8 => addr * 8,
            else => unreachable,
        }
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
