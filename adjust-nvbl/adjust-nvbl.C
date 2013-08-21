/* Adjusts the nvidia backlight using the nvidiabl kernel module found on sourceforge.
 * This program must be setuid in order to communicate with the nvidiabl module. */

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>

#define NVIDIABL "/sys/class/backlight/nvidia_backlight"

static void
usage(const char *arg0, int exit_status)
{
    FILE *f = exit_status ? stderr : stdout;
    fprintf(f, "usage: %s up|dn|show|N\n", arg0);
    exit(exit_status);
}

static long
get_value(const char *filename)
{
    FILE *f = fopen(filename, "r");
    if (!f) {
        perror(filename);
        exit(1);
    }

    static char *line = NULL;
    static size_t linesz = 0;
    if (getline(&line, &linesz, f)<1) {
        fprintf(stderr, "%s: cannot read value\n", filename);
        exit(1);
    }

    errno = 0;
    char *rest = NULL;
    long val = strtol(line, &rest, 0);
    if (errno!=0 || (0==val && rest==line)) {
        fprintf(stderr, "%s: unexpected content\n", filename);
        exit(1);
    }

    fclose(f);
    return val;
}

static void
set_value(const char *filename, long val)
{
    FILE *f = fopen(filename, "w");
    if (!f) {
        perror(filename);
        exit(1);
    }

    if (fprintf(f, "%ld\n", val) < 1) {
        fprintf(stderr, "%s: could write new value\n", filename);
        exit(1);
    }

    if (0!=fclose(f)) {
        perror(filename);
        exit(1);
    }
}

static int
absolute(long newbright)
{
    long maxbright = get_value(NVIDIABL "/max_brightness");
    if (newbright < 0) {
        newbright = 0;
    } else if (newbright > maxbright) {
        newbright = maxbright;
    }
    set_value(NVIDIABL "/brightness", newbright);
}

static int
adjust(long delta)
{
    long curbright = get_value(NVIDIABL "/actual_brightness");
    long newbright = curbright + delta;
    absolute(newbright);
    return 0;
}

int
main(int argc, char *argv[])
{
    long change = 10;
    if (2!=argc)
        usage(argv[0], 1);
    if (!strcmp(argv[1], "up")) {
        adjust(change);
    } else if (!strcmp(argv[1], "dn")) {
        adjust(-change);
    } else if (!strcmp(argv[1], "show")) {
        std::cout <<get_value(NVIDIABL "/actual_brightness") <<"/" <<get_value(NVIDIABL "/max_brightness") <<"\n";
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

    
