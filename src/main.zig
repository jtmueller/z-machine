const std = @import("std");

const KILOBYTES = 1024;
const MAX_STORY_SIZE = 512 * KILOBYTES;

// Z-Machine header information
const VERSION_OFFSET = 0;

const RndGen = std.rand.DefaultPrng;
const testing = std.testing;

const ZMachine = struct {
    memory: [MAX_STORY_SIZE]u8, // 512KB is maximum supported memory for last Z-Machine (v8)
};

var vm = ZMachine{ .memory = undefined };

pub fn main() !void {
    const zork_path = "rom/zork2-r63-s860811.z3";
    var zork_file = try std.fs.cwd().openFile(zork_path, .{});
    defer zork_file.close();

    const expected_file_size = try zork_file.getEndPos();
    const bytes_read = try zork_file.readAll(vm.memory[0..expected_file_size]);
    if (bytes_read != expected_file_size) {
        return std.debug.print("Failed to read entire file: {s}. {d} of {d} bytes read.\n", .{ zork_path, bytes_read, expected_file_size });
    }

    std.debug.print("Z-Machine Information: {}\n", .{vm.memory[VERSION_OFFSET]});
}

test "RNG can repeat with identical seed" {
    var rng = RndGen.init(0);
    const firstValues = [4]i16{ rng.random().int(i16), rng.random().int(i16), rng.random().int(i16), rng.random().int(i16) };

    rng = RndGen.init(0);
    const secondValues = [4]i16{ rng.random().int(i16), rng.random().int(i16), rng.random().int(i16), rng.random().int(i16) };

    try testing.expectEqualSlices(i16, &firstValues, &secondValues);
}

test "RNG should not repeat with different seeds" {
    var seedRng = RndGen.init(0);

    var rng = RndGen.init(seedRng.random().int(u64));
    const firstValues = [4]i16{ rng.random().int(i16), rng.random().int(i16), rng.random().int(i16), rng.random().int(i16) };

    rng = RndGen.init(seedRng.random().int(u64));
    const secondValues = [4]i16{ rng.random().int(i16), rng.random().int(i16), rng.random().int(i16), rng.random().int(i16) };

    for (firstValues, 0..) |_, index| {
        try testing.expect(firstValues[index] != secondValues[index]);
    }
}
