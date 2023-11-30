const std = @import("std");
const This = @This();

const Allocator = std.mem.Allocator;

bits: []u1,

pub fn init(allocator: Allocator, lenBit: usize) std.mem.Allocator.Error!This {
    const bits = try allocator.alloc(u1, lenBit);
    return This{
        .bits = bits,
    };
}

pub fn deinit(this: *This, allocator: Allocator) void {
    allocator.free(this.bits);
}

pub fn add(this: *This, v2: this) void {
    const carry: u1 = 0;
    for (0.., this.bits) |i, *bit| {
        bit.* = bit.* ^ v2.bits[i] ^ carry;
        carry = (bit.* & v2.bits[i]) | (bit.* & carry) | (v2.bits[i] & carry);
    }
}

pub fn copy(this: *This, allocator: Allocator) This {
    const bits = try allocator.alloc(u1, this.bits.len);
    for (bits, this.bits) |*bitTo, *bit| {
        bitTo.* = bit.*;
    }
    return This{
        .bits = bits,
    };
}

pub fn inc(this: *This) void {
    const carry: u1 = 1;
    for (this.bits) |*bit| {
        if (carry == 0) break;
        bit.* = bit.* ^ carry;
        carry = bit.* & carry;
    }
}

pub fn toInt(this: *This) u64 {
    var val: u64 = 0;
    for (this.bits) |*bit| {
        val = (val << 1) | bit.*;
    }
    return val;
}

pub fn sum(allocator: Allocator, these: []This) std.mem.Allocator.Error!This {
    var sumVal = try init(allocator, these[0].bits.len);
    for (these) |this| {
        sumVal.add(this);
    }
    return sumVal;
}
