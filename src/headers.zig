const std = @import("std");
const consts = @import("consts.zig");
const utils = @import("utils.zig");

pub const Headers = struct {
    bytes: []u8,

    const Self = @This();

    pub fn init(memory: []u8) Self {
        return .{
            .bytes = memory[0..64],
        };
    }

    pub fn story_version(self: *Self) u8 {
        return self.bytes[consts.HEADER];
    }

    pub fn initial_pc(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.INITIAL_PC);
    }

    pub fn story_checksum(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.STORY_CHECKSUM);
    }

    pub fn high_mem_base(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.HIGH_MEM_BASE);
    }

    pub fn static_mem_base(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.STATIC_MEM_BASE);
    }

    pub fn dict_loc(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.DICT_OFFSET);
    }

    pub fn obj_loc(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.OBJECTS_OFFSET);
    }

    pub fn globals_loc(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.GLOBALS_OFFSET);
    }

    pub fn abbrev_loc(self: *Self) u16 {
        return utils.read_word(self.bytes, consts.ABBREV_OFFSET);
    }

    pub fn flags1(self: *Self) Flags1 {
        const fv = self.bytes[consts.FLAGS1_OFFSET];
        if (story_version(self) < 4) {
            return .{ .v1_3 = @bitCast(fv) };
        } else {
            return .{ .v4 = @bitCast(fv) };
        }
    }

    pub fn set_flags1(self: *Self, flags: Flags1) void {
        const fv: u8 = switch (flags) {
            .v1_3 => |v| @bitCast(v),
            .v4 => |v| @bitCast(v),
        };
        self.bytes[consts.FLAGS1_OFFSET] = @bitCast(fv);
    }

    pub fn flags2(self: *Self) Flags2 {
        return @bitCast(self.bytes[consts.FLAGS2_OFFSET]);
    }

    pub fn set_flags2(self: *Self, flags: Flags2) void {
        self.bytes[consts.FLAGS2_OFFSET] = @bitCast(flags);
    }

    /// ASCII - usually a date in YYMMDD format.
    pub fn serial(self: *Self) []u8 {
        return self.bytes[consts.SERIAL_OFFSET..][0..6];
    }

    pub fn story_length(self: *Self) u32 {
        const factor: u32 = switch (story_version(self)) {
            1...3 => 2,
            4, 5 => 4,
            6...8 => 8,
            else => 0,
        };
        return @as(u32, utils.read_word(self.bytes, consts.STORY_LENGTH)) * factor;
    }

    /// Interpreter Number
    pub fn int_num(self: *Self) u8 {
        return self.bytes[consts.INT_NUM];
    }

    /// Set Interpreter Number
    pub fn set_int_num(self: *Self, number: u8) void {
        self.bytes[consts.INT_NUM] = number;
    }

    /// Interpreter Version
    pub fn int_ver(self: *Self) u8 {
        return self.bytes[consts.INT_VER];
    }

    /// Set Interpreter Version
    pub fn set_int_ver(self: *Self, version: u8) void {
        self.bytes[consts.INT_VER] = version;
    }

    pub fn screen_size(self: *Self, size_type: SizeType) ScreenSize {
        return switch (size_type) {
            .chars => .{
                .height = self.bytes[consts.SCREEN_HEIGHT_CHARS],
                .width = self.bytes[consts.SCREEN_WIDTH_CHARS],
            },
            .units => .{
                .height = utils.read_word(self.bytes, consts.SCREEN_HEIGHT_UNITS),
                .width = utils.read_word(self.bytes, consts.SCREEN_WIDTH_UNITS),
            },
        };
    }

    pub fn set_screen_size(self: *Self, size: ScreenSize) void {
        switch (size) {
            .chars => |v| {
                self.bytes[consts.SCREEN_HEIGHT_CHARS] = v.height;
                self.bytes[consts.SCREEN_WIDTH_CHARS] = v.width;
            },
            .units => |v| {
                utils.write_word(self.bytes, consts.SCREEN_HEIGHT_UNITS, v.height);
                utils.write_word(self.bytes, consts.SCREEN_WIDTH_UNITS, v.width);
            },
        }
    }
};

pub const SizeType = enum {
    chars,
    units,
};

pub fn Size(comptime T: type) type {
    return struct {
        height: T,
        width: T,
    };
}

pub const ScreenSize = union(SizeType) {
    chars: Size(u8),
    units: Size(u16),
};

pub const Flags1_v1_3 = packed struct(u8) {
    /// Status line should show...
    /// true = hours/mins, false = score/turns
    status_line_hours: bool,
    /// Is story file split across two disks?
    two_disks: bool,
    censored_mode: bool,
    /// Status line not available
    status_na: bool,
    screen_splitting: bool,
    var_width_font: bool,
};

pub const Flags1_v4 = packed struct(u8) {
    colors: bool,
    pictures: bool,
    bold: bool,
    italic: bool,
    fixed_space: bool,
    sounds: bool,
    timed_input: bool,
};

pub const Flags1 = union(enum) {
    v1_3: Flags1_v1_3,
    v4: Flags1_v4,
};

pub const Flags2 = packed struct(u8) {
    transcripting_on: bool,
    screen_redraw_requested: bool,
    pictures_requested: bool,
    undo_requested: bool,
    mouse_requested: bool,
    colors_requested: bool,
    sound_requested: bool,
    menus_requested: bool,
};
