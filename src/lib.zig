const std = @import("std");
const mem = std.mem;
const powci = @import("powci.zig").powci;
const maxInt = std.math.maxInt;

fn Hibitset(comptime Int: type, comptime layers: comptime_int) type {
    const bitc = comptime std.meta.bitCount(Int);
    comptime var layer_offsets: [layers]usize = [_]usize{0} ** layers;
    comptime var sum = 0;
    comptime var i = 0;
    while (i < layers) : (i += 1) {
        layer_offsets[i] = sum;
        comptime var p = powci(bitc, i);
        sum += p;
    }

    return struct {
        const Self = @This();
        const Shift = std.math.Log2Int(Int);
        const bits = bitc;

        layer_data: [sum]Int = [_]Int{0} ** sum,

        pub fn init() Self {
            return Self{};
        }

        fn index_to_end(self: *const Self, index: usize) usize {
            return switch (index) {
                comptime layers - 1 => self.layer_data.len,
                comptime layers...maxInt(usize) => @panic("layer out of bounds"),
                else => layer_offsets[index + 1],
            };
        }

        pub fn layer(self: *Self, index: usize) []Int {
            const end = index_to_end(self, index);
            return self.layer_data[layer_offsets[index]..end];
        }

        pub fn const_layer(self: *const Self, index: usize) []const Int {
            const end = index_to_end(self, index);
            return self.layer_data[layer_offsets[index]..end];
        }

        pub fn set(self: *Self, index: usize) void {
            var lindex = index / bits;
            var bindex = index % bits;
            var current_layer: isize = layers - 1;

            if (self.get(index)) {
                return; // already set
            } else while (current_layer >= 0) : (current_layer -= 1) {
                self.layer(@intCast(usize, current_layer))[lindex] |= @as(Int, 1) << @intCast(Shift, bindex);
                bindex = lindex % bits;
                lindex /= bits;
            }
        }

        pub fn unset(self: *Self, index: usize) void {
            var lindex = index / bits;
            var bindex = index % bits;
            var current_layer: isize = layers - 1;

            if (!self.get(index)) {
                return; // already unset
            } else while (current_layer >= 0) : (current_layer -= 1) {
                var block = &self.layer(@intCast(usize, current_layer))[lindex];
                block.* &= ~(@as(Int, 1) << @intCast(Shift, bindex));
                if (block.* != 0) {
                    break;
                }
                bindex = lindex % bits;
                lindex /= bits;
            }
        }

        pub fn get(self: *const Self, index: usize) bool {
            var lindex = index / bits;
            var bindex = index % bits;
            return (self.const_layer(layers - 1)[lindex] >> @intCast(Shift, bindex)) & 0x01 != 0;
        }

        pub fn clear(self: *Self) void {
            for (self.layer_data) |*l| {
                l.* = 0;
            }
        }

        pub fn is_empty(self: *const Self) bool {
            return self.const_layer(0)[0] == 0;
        }

        pub fn eq(self: *const Self, other: *const Self) bool {
            comptime var l = 0;
            return inline while (l < layers) : (l += 1) {
                if (!mem.eql(Int, self.const_layer(l), other.const_layer(l))) {
                    break false;
                }
            } else true;
        }
    };
}

test "f" {
    const Set = Hibitset(usize, 4);
    var set = Set.init();

    std.debug.warn("{}\n", .{@typeInfo(Set.Shift)});
    std.debug.warn("{}\n", .{Set.bits});
    var l: usize = 0;
    while (l < 2) : (l += 1) {
        for (set.layer(l)) |i| {
            std.debug.warn("{b:0>4}|", .{i});
        }
        std.debug.warn("\n", .{});
    }
}

test "set check" {
    const Set = Hibitset(u4, 3);
    var set = Set.init();
    var i: usize = 0;
    while (i < powci(4, 3)) : (i += 1) {
        set.set(i);
        std.debug.assert(set.get(i));
    }
}

test "set unset check" {
    const Set = Hibitset(u4, 3);
    var set = Set.init();
    var i: usize = 0;
    while (i < powci(4, 3)) : (i += 1) {
        set.set(i);
        set.unset(i);
        std.debug.assert(!set.get(i));
    }
}

test "set all unset interleaved check" {
    const Set = Hibitset(u4, 3);
    var set = Set.init();
    var i: usize = 0;
    while (i < powci(4, 3)) : (i += 1) {
        if (i % 2 == 0) {
            set.set(i);
        }
    }
    i = 0;
    while (i < powci(4, 3)) : (i += 1) {
        if (i % 4 == 0) {
            set.unset(i);
        }
    }
    for (set.layer(0)) |x| {
        std.debug.assert(x == 0b1111);
    }
    for (set.layer(1)) |x| {
        std.debug.assert(x == 0b1111);
    }
    for (set.layer(2)) |x| {
        std.debug.assert(x == 0b0100);
    }
}

test "clear" {
    const Set = Hibitset(u4, 3);
    var set = Set.init();
    var i: usize = 0;
    while (i < powci(4, 3)) : (i += 1) {
        set.set(i);
    }
    set.clear();
    for (set.layer_data) |l| {
        std.debug.assert(l == 0);
    }
}

test "is_empty" {
    const Set = Hibitset(u4, 3);
    var set = Set.init();
    std.debug.assert(set.is_empty());
}

test "eq" {
    const Set = Hibitset(u4, 3);
    var set = Set.init();
    var set2 = Set.init();
    const set3 = Set.init();

    var i: usize = 0;
    while (i < powci(4, 3)) : (i += 1) {
        if (i % 4 == 0) {
            set.set(i);
            set2.set(i);
        }
    }
    std.debug.assert(set.eq(&set2));
    std.debug.assert(!set.eq(&set3));
}
