const std = @import("std");
const testing = std.testing;

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