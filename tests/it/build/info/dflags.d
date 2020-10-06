module it.build.info.dflags;


import it;
import bud.api;
import bud.build.info;
import std.algorithm: map;


@("simplest.dmd")
@safe unittest {

    import dub.compilers.buildsettings;

    import std.path: buildPath;

    with(immutable BudSandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
            ]
        );

        writeDubSelections;

        writeFile("source/app.d",
                  "void main() {}");

        const tgts = targets(
            ProjectPath(testPath),
            UserPackagesPath(),
            Compiler.dmd,
        );

        tgts.map!(a => a.dflags).should == [["-debug", "-g", "-w"]];
    }
}


@("simplest.ldc")
@safe unittest {

    import dub.compilers.buildsettings;
    import std.path: buildPath;

    with(immutable BudSandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
            ]
        );

        writeDubSelections;

        writeFile("source/app.d",
                  "void main() {}");

        const tgts = targets(
            ProjectPath(testPath),
            UserPackagesPath(),
            Compiler.ldc,
        );

        tgts.map!(a => a.dflags).should ==
            [["-d-debug", "-g", "-w", "-oq", "-od=.dub/obj"]];
    }
}


@("simplest.gdc")
@safe unittest {

    import dub.compilers.buildsettings;
    import std.path: buildPath;

    with(immutable BudSandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
            ]
        );

        writeDubSelections;

        writeFile("source/app.d",
                  "void main() {}");

        const tgts = targets(
            ProjectPath(testPath),
            UserPackagesPath(),
            Compiler.gdc,
        );

        tgts.map!(a => a.dflags).should == [["-fdebug", "-g", "-Werror", "-Wall"]];
    }
}



@("dependencies.dmd")
@safe unittest {

    import dub.compilers.buildsettings;
    import std.path: buildPath;

    with(immutable BudSandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
                `dependency "bar" version="*"`,
            ]
        );

        writeDubSelections(["bar": "1.2.3"]);

        writeFile("source/app.d", q{void main() {}});

        writeDownloadedDubSdl("userpath", "bar", "1.2.3",
                  [
                      `name "bar"`,
                      `targetType "library"`,
                      `dflags "-preview=dip1000"`,
                  ]
        );

        writeFile(buildPath(pkgPath("userpath", "bar", "1.2.3"), "source", "bar.d"),
                  "int add1(int i, int j) { return i + j; }");

        const tgts = targets(
            ProjectPath(testPath),
            UserPackagesPath(inSandboxPath("userpath")),
            Compiler.dmd,
        );

        // apparently dflags is viral
        tgts.map!(a => a.dflags).should == [
            ["-preview=dip1000", "-debug", "-g", "-w"],
            ["-preview=dip1000", "-debug", "-g", "-w"],
        ];
    }
}
