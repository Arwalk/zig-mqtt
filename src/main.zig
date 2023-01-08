const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;

const MessageType = enum(u4) {
    CONNECT = 1,
    CONNACK,
    PUBLISH,
    PUBACK,
    PUBREC,
    PUBREL,
    PUBCOMP,
    SUBSCRIBE,
    SUBACK,
    UNSUBSCRIBE,
    UNSUBACK,
    PINGREQ,
    PINGRESP,
    DISCONNECT 
};


test "Message type values" {
    try testing.expect(@enumToInt(MessageType.CONNECT) == 1);
    try testing.expect(@enumToInt(MessageType.CONNACK) == 2);
    try testing.expect(@enumToInt(MessageType.PUBLISH) == 3);
    try testing.expect(@enumToInt(MessageType.PUBACK) == 4);
    try testing.expect(@enumToInt(MessageType.PUBREC) == 5);
    try testing.expect(@enumToInt(MessageType.PUBREL) == 6);
    try testing.expect(@enumToInt(MessageType.PUBCOMP) == 7);
    try testing.expect(@enumToInt(MessageType.SUBSCRIBE) == 8);
    try testing.expect(@enumToInt(MessageType.SUBACK) == 9);
    try testing.expect(@enumToInt(MessageType.UNSUBSCRIBE) == 10);
    try testing.expect(@enumToInt(MessageType.UNSUBACK) == 11);
    try testing.expect(@enumToInt(MessageType.PINGREQ) == 12);
    try testing.expect(@enumToInt(MessageType.PINGRESP) == 13);
    try testing.expect(@enumToInt(MessageType.DISCONNECT) == 14);    
}

const QoS = enum(u2) {
    FireAndForget,
    AcknowledgedDelivery,
    AssuredDelivery,
};

test "QoS values" {
    try testing.expect(@enumToInt(QoS.FireAndForget) == 0);
    try testing.expect(@enumToInt(QoS.AcknowledgedDelivery) == 1);
    try testing.expect(@enumToInt(QoS.AssuredDelivery) == 2);
}

const VariableLengthValueError = error {
    TooBig,
    OutOfMemory
};

const MaxValueInVariableLength : u32 = 268_435_455;

fn encodeValueToVariableLengthValue(value : u32, stream : *ArrayList(u8)) VariableLengthValueError!*ArrayList(u8) {
    if(value > MaxValueInVariableLength) {
        return VariableLengthValueError.TooBig;
    }

    if(value == 0) {
        try stream.append(0);
    }

    var x = value;
    while (x > 0) {
        var digit = @truncate(u8, x % 128);
        x = @divFloor(x, 128);
        if(x > 0) {
            digit = digit | 0x80;
        }
        try stream.append(digit);
    }
    return stream;
}


fn testFuncCheck_encodeValueToVariableLengthValue(value: u32, expected: []const u8) !void {
    var stream = ArrayList(u8).init(testing.allocator);
    defer stream.deinit();

    _ = try encodeValueToVariableLengthValue(value, &stream);
    try testing.expectEqualSlices(u8, expected, stream.items);
}

test "valueToVariableLengthValue" {

    try testFuncCheck_encodeValueToVariableLengthValue(0, &[_]u8{0});
    try testFuncCheck_encodeValueToVariableLengthValue(127, &[_]u8{0x7F});
    try testFuncCheck_encodeValueToVariableLengthValue(128, &[_]u8{0x80, 0x01});
    try testFuncCheck_encodeValueToVariableLengthValue(16_383, &[_]u8{0xFF, 0x7F});
    try testFuncCheck_encodeValueToVariableLengthValue(16_384, &[_]u8{0x80, 0x80, 0x01});
    try testFuncCheck_encodeValueToVariableLengthValue(2_097_151, &[_]u8{0xFF, 0xFF, 0x7F});
    try testFuncCheck_encodeValueToVariableLengthValue(2_097_152, &[_]u8{0x80, 0x80, 0x80, 0x01});
    try testFuncCheck_encodeValueToVariableLengthValue(268_435_455, &[_]u8{0xFF, 0xFF, 0xFF, 0x7F});

    var stream = ArrayList(u8).init(testing.allocator);
    try testing.expectError(VariableLengthValueError.TooBig, encodeValueToVariableLengthValue(MaxValueInVariableLength + 1, &stream));
}

pub const MessageParser = struct {
    data : []const u8,
    index: usize = 0,

    pub fn init(data : []const u8) MessageParser {
        return MessageParser{
            .data = data
        };
    }

    fn decodeVariableLengthValueToValue(self: *MessageParser) VariableLengthValueError!u32 {
        var multiplier : u32 = 128;
        var digit : u32 = @as(u32, self.data[self.index]);
        var value : u32 = digit & 127;
        var base_index : usize = 1;
        while((digit & 128) != 0) {
            if(base_index == 4) {
                return VariableLengthValueError.TooBig;
            }
            digit = @as(u32, self.data[self.index + base_index]);
            base_index += 1;
            value += (digit & 127) * multiplier;
            multiplier *= 128;
        }
        self.index += base_index;
        return value;
    }
};



fn testFuncCheck_decodeVariableLengthToValue(data : []const u8, expected: u32) !void {
    var message = MessageParser.init(data);
    const result = try message.decodeVariableLengthValueToValue();

    try testing.expectEqual(expected, result);
}

test "variableLengthValueToValue" {
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0}, 0);
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0x7F}, 127);
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0x80, 0x01}, 128);
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0xFF, 0x7F}, 16_383);
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0x80, 0x80, 0x01}, 16_384);
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0xFF, 0xFF, 0x7F}, 2_097_151);
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0x80, 0x80, 0x80, 0x01}, 2_097_152);
    try testFuncCheck_decodeVariableLengthToValue(&[_]u8{0xFF, 0xFF, 0xFF, 0x7F}, 268_435_455);

    var message = MessageParser.init(&[_]u8{0xFF, 0xFF, 0xFF, 0x7F + 1});
    try testing.expectError(VariableLengthValueError.TooBig, message.decodeVariableLengthValueToValue());
}