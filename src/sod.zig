const math = @import("std").math;

pub fn Sod2D(comptime T: type) type {
    return struct {
        const Self = @This();

        k1: T,
        k2: T,
        k3: T,
        p_dst_x: T,
        p_dst_y: T,
        pos_x: T,
        pos_y: T,
        acc_x: T,
        acc_y: T,

        pub fn init(f: T, z: T, r: T) Sod2D(T) {
            var self = Sod2D(T){
                .k1 = undefined,
                .k2 = undefined,
                .k3 = undefined,

                .p_dst_x = 0,
                .p_dst_y = 0,

                .pos_x = 0,
                .pos_y = 0,

                .acc_x = 0,
                .acc_y = 0,
            };
            self.configure(f, z, r);
            return self;
        }

        pub fn configure(self: *Self, f: T, z: T, r: T) void {
            const pi = math.pi;
            self.k1 = z / (pi * f);
            self.k2 = 1 / ((2 * pi * f) * (2 * pi * f));
            self.k3 = r * z / (2 * pi * f);
        }

        pub fn reset(self: *Self, dst_x: T, dst_y: T) void {
            self.p_dst_x = dst_x;
            self.p_dst_y = dst_y;
            self.pos_x = dst_x;
            self.pos_y = dst_y;
            self.acc_x = 0;
            self.acc_y = 0;
        }

        pub fn update(self: *Self, delta_time: T, dst_x: T, dst_y: T) void {
            if (delta_time == 0) {
                return;
            }

            // Estimate velocity.
            const xd_x: T = (dst_x - self.p_dst_x) / delta_time;
            const xd_y: T = (dst_y - self.p_dst_y) / delta_time;
            self.p_dst_x = dst_x;
            self.p_dst_y = dst_y;

            // Clamp k2 to guarantee stability without jitter.
            const k2_stable: T = @max(self.k2, @max(delta_time * delta_time / 2 + delta_time * self.k1 / 2, delta_time * self.k1));

            // Integrate position by velocity.
            self.pos_x += delta_time * self.acc_x;
            self.pos_y += delta_time * self.acc_y;

            // Integrate velocity by acceleration.
            self.acc_x += delta_time * (dst_x + self.k3 * xd_x - self.pos_x - self.k1 * self.acc_x) / k2_stable;
            self.acc_y += delta_time * (dst_y + self.k3 * xd_y - self.pos_y - self.k1 * self.acc_y) / k2_stable;
        }
    };
}
