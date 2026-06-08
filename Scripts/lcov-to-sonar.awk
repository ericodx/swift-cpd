#!/usr/bin/awk -f
#
# Converts LCOV (output of `llvm-cov export --format=lcov`) into the generic
# coverage XML format consumed by SonarCloud / SonarQube.
#
# Usage:
#   awk -f Scripts/lcov-to-sonar.awk < input.lcov > output.xml
#
# The XML envelope (<coverage version="1"> ... </coverage>) is emitted by this
# script. Only files under Sources/*.swift are included; everything else is
# filtered out so the report does not include Tests or build artifacts.

BEGIN {
    print "<coverage version=\"1\">"
}

/^SF:/ {
    file = substr($0, 4)
    if (file ~ /^Sources\/.*\.swift$/) {
        printf "  <file path=\"%s\">\n", file
        inside = 1
    } else {
        inside = 0
    }
}

inside && /^DA:/ {
    split($0, a, ",")
    line = substr(a[1], 4)
    covered = (a[2] > 0 ? "true" : "false")
    printf "    <lineToCover lineNumber=\"%s\" covered=\"%s\"/>\n", line, covered
}

inside && /^end_of_record/ {
    print "  </file>"
}

END {
    print "</coverage>"
}
