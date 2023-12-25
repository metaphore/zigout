const math = @import("std").math;

pub fn SpecializeOn(comptime T: type) type {
    return struct {
        
        pub const Sod2 = struct {
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

            pub fn new(f: T, z: T, r: T) Self {
                var self = Self{
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

        pub const sod2 = Sod2.new;

        
        // pub const Sod1 = SodBase(1);
        // pub const Sod2 = SodBase(2);
        // pub const Sod3 = SodBase(3);
        // pub const Sod4 = SodBase(4);

        // pub const sod1 = Sod1.new;
        // pub const sod2 = Sod2.new;
        // pub const sod3 = Sod3.new;
        // pub const sod4 = Sod4.new;
       
        // fn SodBase(comptime size: usize) type { 
        //     return struct {
        //         const Self = @This();

        //         const Dimen = struct {
        //             p_dst: T,
        //             pos: T,
        //             acc: T,
        //         };
                
        //         k1: T,
        //         k2: T,
        //         k3: T,
        //         dimens: [size]Dimen,

        //         pub fn new(f: T, z: T, r: T, dsts: [size]T) Self {
        //             var self = Self{
        //                 .k1 = undefined,
        //                 .k2 = undefined,
        //                 .k3 = undefined,
        //                 .dimens = undefined,
        //             };
        //             self.configure(f, z, r);
        //             self.reset(dsts);
        //             return self;
        //         }

        //         pub fn configure(self: *Self, f: T, z: T, r: T) void {
        //             const pi = math.pi;
        //             self.k1 = z / (pi * f);
        //             self.k2 = 1 / ((2 * pi * f) * (2 * pi * f));
        //             self.k3 = r * z / (2 * pi * f);
        //         }

        //         pub fn reset(self: *Self, dsts: [size]T) void {
        //             for (0.., dsts) |i, dst| {
        //                 const dimen = &self.dimens[i];
        //                 dimen.p_dst = dst;
        //                 dimen.pos = dst;
        //                 dimen.acc = 0;
        //             }
        //         }

        //         pub fn pos(self: *Self, index: usize) T {
        //             return self.dimens[index].pos;
        //         }

        //         pub fn update(self: *Self, delta_time: T, dsts: [size]T) void {
        //             if (delta_time == 0) {
        //                 return;
        //             }

        //             // Clamp k2 to guarantee stability without jitter.
        //             const k2_stable: T = @max(self.k2, @max(delta_time * delta_time / 2 + delta_time * self.k1 / 2, delta_time * self.k1));

        //             for (0.., &self.dimens) |i, *dimen| {
        //                 const dst = dsts[i];
        //                 // Estimate velocity.
        //                 const xd: T = (dst - dimen.p_dst) / delta_time;
        //                 // Integrate position by velocity.
        //                 dimen.pos += delta_time * dimen.acc;
        //                 // Integrate velocity by acceleration.
        //                 dimen.acc += delta_time * (dst + self.k3 * xd - dimen.pos - self.k1 * dimen.acc) / k2_stable;
        //             }
        //         }
        //     };
        // }
    };
}

pub usingnamespace SpecializeOn(f32);
