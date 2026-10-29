"""Elaborate SystemVerilog sources with slang (pyslang) and report diagnostics.

Usage: python3 -I slang_elab.py <slang command-line arguments...>
Exit status 0 when elaboration produced no errors, 1 otherwise.
"""
import sys

import pyslang


def main(argv):
    driver = pyslang.driver.Driver()
    driver.addStandardArgs()
    if not driver.parseCommandLine("slang " + " ".join(argv),
                                   pyslang.driver.CommandLineOptions()):
        return 1
    if not (driver.processOptions() and driver.parseAllSources()):
        return 1
    compilation = driver.createCompilation()
    driver.reportCompilation(compilation, False)
    diags = compilation.getAllDiagnostics()
    errors = sum(1 for d in diags if d.isError())
    v = pyslang.VersionInfo
    print(f"SLANG_RESULT: errors={errors} diagnostics={len(diags)} "
          f"slang={v.getMajor()}.{v.getMinor()}.{v.getPatch()}+{v.getHash()}")
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
