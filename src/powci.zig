const builtin = @import("builtin");
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const testing = std.testing;

pub fn powci(comptime x: comptime_int, y: comptime_int) comptime_int {
    return if (y == 0)
        1
    else switch (x) {
        0 => 0,
        1 => 1,
        else => blk: {
            if (x == -1) {
                return if (y % 2 == 0) 1 else -1;
            }

            comptime var base = x;
            comptime var exp = y;
            comptime var acc = 1;

            while (exp > 1) {
                if (exp & 1 == 1) {
                    acc = acc * base;
                }

                exp >>= 1;
                base = base * base;
            }

            if (exp == 1) {
                acc = acc * base;
            }

            break :blk acc;
        },
    };
}

// tests from zig std powi

test "math.powci" {
    testing.expect(powci(-5, 3) == -125);
    testing.expect(powci(-16, 3) == -4096);
    testing.expect(powci(-91, 3) == -753571);
    testing.expect(powci(-36, 6) == 2176782336);
    testing.expect(powci(-2, 15) == -32768);
    testing.expect(powci(-5, 7) == -78125);

    testing.expect(powci(6, 2) == 36);
    testing.expect(powci(5, 4) == 625);
    testing.expect(powci(12, 6) == 2985984);
    testing.expect(powci(34, 2) == 1156);
    testing.expect(powci(16, 3) == 4096);
    testing.expect(powci(34, 6) == 1544804416);
}

test "math.powci.special" {
    testing.expect(powci(-1, 3) == -1);
    testing.expect(powci(-1, 2) == 1);
    testing.expect(powci(-1, 16) == 1);
    testing.expect(powci(-1, 6) == 1);
    testing.expect(powci(-1, 15) == -1);
    testing.expect(powci(-1, 7) == -1);

    testing.expect(powci(1, 2) == 1);
    testing.expect(powci(1, 4) == 1);
    testing.expect(powci(1, 6) == 1);
    testing.expect(powci(1, 2) == 1);
    testing.expect(powci(1, 3) == 1);
    testing.expect(powci(1, 6) == 1);

    testing.expect(powci(6, 0) == 1);
    testing.expect(powci(5, 0) == 1);
    testing.expect(powci(12, 0) == 1);
    testing.expect(powci(34, 0) == 1);
    testing.expect(powci(16, 0) == 1);
    testing.expect(powci(34, 0) == 1);
}
