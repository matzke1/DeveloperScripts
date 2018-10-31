/* Adjusts the nvidia backlight using the nvidiabl kernel module found on sourceforge.
 * This program must be setuid in order to communicate with the nvidiabl module. */

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <unistd.h>

#define NVIDIABL "/sys/class/backlight/nvidia_backlight"
#define INTELBL "/sys/class/backlight/intel_backlight"

static void
usage(const char *arg0, int exit_status)
{
    FILE *f = exit_status ? stderr : stdout;
    fprintf(f, "usage: %s up|dn|show|N\n", arg0);
    exit(exit_status);
}

std::string
base_name() {
    if (access(NVIDIABL, X_OK) == 0)
        return NVIDIABL;
    if (access(INTELBL, X_OK) == 0)
        return INTELBL;
    return "";
}

static long
get_value(const std::string &filename) {
    FILE *f = fopen(filename.c_str(), "r");
    if (!f) {
        perror(filename.c_str());
        exit(1);
    }

    static char *line = NULL;
    static size_t linesz = 0;
    if (getline(&line, &linesz, f)<1) {
        std::cerr <<filename <<": cannot read value\n";
        exit(1);
    }

    errno = 0;
    char *rest = NULL;
    long val = strtol(line, &rest, 0);
    if (errno!=0 || (0==val && rest==line)) {
        std::cerr <<filename <<": unexpected content\n";
        exit(1);
    }

    fclose(f);
    return val;
}

static void
set_value(const std::string &filename, long val) {
    FILE *f = fopen(filename.c_str(), "w");
    if (!f) {
        perror(filename.c_str());
        exit(1);
    }

    if (fprintf(f, "%ld\n", val) < 1) {
        std::cerr <<filename <<": could not write new value\n";
        exit(1);
    }

    if (0!=fclose(f)) {
        perror(filename.c_str());
        exit(1);
    }
}

static int
absolute(long newbright) {
    long maxbright = get_value(base_name() + "/max_brightness");
    if (newbright < 0) {
        newbright = 0;
    } else if (newbright > maxbright) {
        newbright = maxbright;
    }
    set_value(base_name() + "/brightness", newbright);
}

static int
adjust(long delta) {
    long curbright = get_value(base_name() + "/actual_brightness");
    long newbright = curbright + delta;
    absolute(newbright);
    return 0;
}

int
main(int argc, char *argv[]) {
    long change = 10;
    if (2!=argc)
        usage(argv[0], 1);
    if (!strcmp(argv[1], "up")) {
        adjust(change);
    } else if (!strcmp(argv[1], "dn")) {
        adjust(-change);
    } else if (!strcmp(argv[1], "show")) {
        std::cout <<get_value(base_name() + "/actual_brightness")
                  <<"/" <<get_value(base_name() + "/max_brightness") <<"\n";
    } else if (isdigit(argv[1][0])) {
        char *rest = NULL;
        long newbright = strtol(argv[1], &rest, 0);
        if (*rest)
            usage(argv[0], 1);
        absolute(newbright);
    } else {
        usage(argv[0], 1);
    }
    exit(0);
}

    
