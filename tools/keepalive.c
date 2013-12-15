/*
 * Copyright © 2000 Robb Matzke.
 *                  All rights reserved.
 *
 * Programmer:  Robb Matzke <matzke@wcrtc.net>
 *              Sunday, September 17, 2000
 */
#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <pty.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define TIMEOUT         9*60 /*seconds*/
#define DELETE_CHAR     "\177" /* DEL */

#define SET             (-1)

static struct termios   orig_tt;
static sig_atomic_t     alarmed = 0;
static int              timeout_g = TIMEOUT;

/**/
static void
usage(const char *message)
{
    fprintf(stderr, "keepalive: %s\n",  message);
    fprintf(stderr, "usage: keepalive [-i N | --interval=N] COMMAND [ARGUMENTS]\n");
    fprintf(stderr, "    Run COMMAND with ARGUMENTS.\n");
    fprintf(stderr, "    Every N seconds send a space followed by a delete.\n");
    exit(1);
}

/**/
static void
do_alarm(int signo)
{
    static int ncalls = 0;
    if (signo<0) {
        if (0==ncalls++) {
            struct sigaction sa;
            sa.sa_handler = do_alarm;
            sigemptyset(&sa.sa_mask);
            sa.sa_flags = 0;
            sigaction(SIGALRM, &sa, NULL);
        }
        alarmed = 0;
        alarm(timeout_g);
    } else {
        alarmed = 1;
    }
}

/* reap child and exit */
static void
reap_child_and_exit(int signo)
{
    int status;
    
    tcsetattr(0, TCSAFLUSH, &orig_tt);
    if (waitpid(WAIT_ANY, &status, 0)>=0) {
        if (WIFEXITED(status)) exit(WEXITSTATUS(status));
        exit(1); /*child died due to signal*/
    }
    abort(); /*waitpid should have succeeded*/
}

/**/
int
main(int argc, char *argv[]) 
{
    int                 master, argno, i;
    ssize_t             n;
    char                buf[64], *rest;
    const char          *name;
    struct termios      rtt;
    struct winsize      win;
    pid_t               child;

    /* Parse command-line switches */
    for (argno=1; argno<argc; argno++) {
        if (!strncmp(argv[argno], "-i", 2)) {
            if (argv[argno][2]) {
                i = strtol(argv[argno]+2, &rest, 0);
                if ((rest && *rest) || i<=0) usage("invalid argument for `-i'"); /*noreturn*/
                timeout_g = i;
            } else if (argno+1<argc) {
                argno++;
                i = strtol(argv[argno], &rest, 0);
                if ((rest && *rest) || i<=0) usage("invalid argument for `-i'"); /*noreturn*/
                timeout_g = i;
            } else {
                usage("`-i' requires an argument"); /*noreturn*/
            }
        } else if (!strncmp(argv[argno], "--interval=", 11)) {
            i = strtol(argv[argno]+11, &rest, 0);
            if ((rest && *rest) || i<=0) usage("invalid argument for `--interval'"); /*noreturn*/
            timeout_g = i;
        } else if (!strncmp(argv[argno], "--interval", 10)) {
            usage("`--interval' requires an argument"); /*noreturn*/
        } else if (!strcmp(argv[argno], "--")) {
            argno++;
            break;
        } else if ('-'==argv[argno][0]) {
            char *mesg = malloc(32+strlen(argv[argno]));
            if (mesg) {
                sprintf(mesg, "unknown switch `%s'", argv[argno]);
            } else {
                mesg = "unknown switch";
            }
            usage(mesg); /*noreturn*/
        } else {
            break;
        }
    }
    if (argno>=argc) usage("no command to execute"); /*noreturn*/
    
    /* Get window information */
    tcgetattr(0, &orig_tt);
    ioctl(0, TIOCGWINSZ, &win);
    
    /* Open master pty */
    if ((master=getpt())<0) {
        perror("getpt");
        return 1;
    }
    if (grantpt(master)<0) {
        perror("grantpt");
        return 1;
    }
    if (unlockpt(master)<0) {
        perror("unlockpt");
        return 1;
    }
    if (NULL==(name=ptsname(master))) {
        perror("ptsname");
        return 1;
    }

    /* Make parent stdin raw */
    rtt = orig_tt;
    cfmakeraw(&rtt);
    rtt.c_lflag &= ~ECHO;
    tcsetattr(0, TCSAFLUSH, &rtt);

    signal(SIGCHLD, reap_child_and_exit);
    if ((child=fork())<0) {
        perror("fork");
        tcsetattr(0, TCSAFLUSH, &orig_tt);
        exit(1);
    } else if (!child) {
        /* Execute command child */
        int slave = open(name, O_RDWR);
        if (slave < 0) {
            perror(name);
            exit(1);
        }
        tcsetattr(slave, TCSAFLUSH, &orig_tt);
        ioctl(slave, TIOCSWINSZ, &win);
        setsid();
        ioctl(slave, TIOCSCTTY, 0);

        close(master);
        dup2(slave, 0);
        dup2(slave, 1);
        dup2(slave, 2);
        close(slave);
        execvp(argv[argno], argv+argno);
        perror(argv[argno]);
        exit(1);
    }

    /* Handle input in parent */
    do_alarm(SET);
    while (1) {
        struct timeval tv;
        fd_set  rdset;
        int nready;
        
        FD_ZERO(&rdset);
        FD_SET(0, &rdset);
        FD_SET(master, &rdset);
        tv.tv_sec = 1;
        tv.tv_usec = 0;
        nready = select(master+1, &rdset, NULL, NULL, &tv);
        if (alarmed) {
            TEMP_FAILURE_RETRY(write(master, " " DELETE_CHAR, 2));
            do_alarm(SET);
#if 1
            /* Test code triggered by alarm: trying to determine how to notify the slave
             * of a window size change. Eventually this would all be triggered by reception
             * of SIGWINCH. */
            fprintf(stderr, "ALARM\b\b\b\b\b");
            fflush(stderr);
#if 0
            ioctl(master, TIOCGWINSZ, &win);
            ioctl(master, TIOCSWINSZ, &win);
#else
            kill(-child, SIGWINCH);
#endif
#endif
        }
        if (nready>0 && FD_ISSET(0, &rdset)) {
            n = TEMP_FAILURE_RETRY(read(0, buf, sizeof buf));
            if (n<0) goto error;
            n = TEMP_FAILURE_RETRY(write(master, buf, n));
            if (n<0) goto error;
            do_alarm(SET);
        }
        if (nready>0 && FD_ISSET(master, &rdset)) {
            n = TEMP_FAILURE_RETRY(read(master, buf, sizeof buf));
            if (n<0) goto error;
            n = TEMP_FAILURE_RETRY(write(1, buf, n));
            if (n<0) goto error;
        }
    }

 error:
    tcsetattr(0, TCSAFLUSH, &orig_tt);
    return 1;
}
