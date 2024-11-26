const std = @import("std");

/// Reads a word from the given bytes at the given address, converting from big-endian if needed.
pub inline fn read_word(bytes: []u8, addr: usize) u16 {
    return std.mem.readInt(u16, bytes[addr..][0..2], .big);
}

/// Wraites a word into the given bytes at the given address, converting to big-endian if needed.
pub inline fn write_word(bytes: []u8, addr: usize, value: u16) void {
    std.mem.writeInt(u16, bytes[addr..][0..2], value, .big);
}
