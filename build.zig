const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    //  Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall
    const optimize = b.standardOptimizeOption(.{});

    Generator.init(b, &target, &optimize);

    const main = Main.init(b, &target, &optimize);
    main.runStep(b, b.args);
    main.testStep(b);
}

const Generator = struct {
    pub fn init(
        b: *std.Build,
        target: *const std.zig.CrossTarget,
        optimize: *const std.builtin.OptimizeMode,
    ) void {
        const exe = b.addExecutable(.{
            .name = "generate-file",
            .root_source_file = .{ .path = "src/generate-file.zig" },
            .target = target.*,
            .optimize = optimize.*,
        });
        const step = b.step(
            "generate",
            "Generate file",
        );
        const run_cmd = b.addRunArtifact(exe);
        step.dependOn(&run_cmd.step);
    }
};

const Main = struct {
    exe: *std.Build.Step.Compile,
    target: *const std.zig.CrossTarget,
    optimize: *const std.builtin.OptimizeMode,

    fn getName(optimize: *const std.builtin.OptimizeMode) []const u8 {
        if (optimize.* == std.builtin.OptimizeMode.Debug) {
            return "tinyficator-debug";
        }
        return "tinyficator";
    }

    pub fn init(
        b: *std.Build,
        target: *const std.zig.CrossTarget,
        optimize: *const std.builtin.OptimizeMode,
    ) *const Main {
        const exe = b.addExecutable(.{
            .name = getName(optimize),
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target.*,
            .optimize = optimize.*,
        });
        b.installArtifact(exe);

        return &Main{
            .exe = exe,
            .target = target,
            .optimize = optimize,
        };
    }

    pub fn runStep(self: *const Main, b: *std.Build, args: ?[][]const u8) void {
        const run_cmd = b.addRunArtifact(self.exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (args) |arg| {
            run_cmd.addArgs(arg);
        }
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    pub fn testStep(self: *const Main, b: *std.Build) void {
        const exe_unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = self.target.*,
            .optimize = self.optimize.*,
        });

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }
};
