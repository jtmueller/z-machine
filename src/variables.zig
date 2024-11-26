const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub const VariableSlotsError = error{
    SizeExceedsByteCapacity,
    SlotOutOfRange,
};

pub const VariableSlots = struct {
    bytes: []u8,
    len: usize,
    bytes_owned: bool,

    const Self = @This();

    pub fn init_bytes(bytes: []u8) Self {
        return .{
            .bytes = bytes,
            .len = bytes.len / 2,
            .bytes_owned = false,
        };
    }

    pub fn init_size(size: u8, allocator: Allocator) !Self {
        return .{
            .bytes = try allocator.alloc(u8, size * 2),
            .len = size,
            .bytes_owned = true,
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        if (self.bytes_owned) {
            allocator.free(self.bytes);
        }
        self.bytes = &.{};
        self.len = 0;
    }

    pub fn get(self: *Self, slot: u8) !u16 {
        if (slot > self.len) {
            return VariableSlotsError.SlotOutOfRange;
        }

        return utils.read_word(self.bytes, slot * 2);
    }

    pub fn set(self: *Self, slot: u8, value: u16) !void {
        if (slot > self.len) {
            return VariableSlotsError.SlotOutOfRange;
        }

        return utils.write_word(self.bytes, slot * 2, value);
    }
};
