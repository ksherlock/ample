

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <libgen.h>
#include <paths.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sysexits.h>
#include <termios.h>
#include <unistd.h>
#include <util.h>

#define TTYDEFCHARS
#include <sys/ttydefaults.h>


void usage(int rv) {

	fputs(
		"Usage: pty_shell [-T term] [-w] [-r] pty [command ...]\n"
		"       -T term     TERM (default vt100)\n"
		"       -w          Don't wait for child to finish\n"
		"       -r          Raw I/O\n"
		, stderr);
	exit(rv);
}


char *xsprintf(char *fmt, ...) {

	int ok;
	char *buffer = NULL;
	va_list ap;

	va_start(ap, fmt);
	ok = vasprintf(&buffer, fmt, ap);
	if (ok < 0) {
		errx(EX_SOFTWARE, "vasprintf failed");
	}
	va_end(ap);
	return buffer;
}

/* re-create execve path search so we have better control */
/* return string may or may not be allocated */
char *findexe(char *name) {

	struct stat st;
	char *cp;
	int ok;

	char *path = getenv("PATH");
	if (!path) path = _PATH_DEFPATH;

	if (!name || !*name) {
		errno = ENOENT;
		return NULL;
	}
	if (*name == '/') return name;
	if (strchr(name, '/')) {
		cp = realpath(name, NULL);
		return cp;
	}

	char *start = path;
	char *end = NULL;
	size_t l;

	for(;;) {
		end = strchr(start, ':');
		if (!end) {
			/* last one */
			l = strlen(start);
		} else {
			l = end - start;
		}
		if (l == 0) {
			/* current directory */
			cp = realpath(name, NULL);
		} else {
			cp = xsprintf("%.*s/%s", l, start, name);
		}

		// fprintf(stderr, "%s\n", cp);
		ok = stat(cp, &st);

		if (ok >= 0 && (st.st_mode & S_IXUSR))
			return cp;

		free(cp);

		if (!end) break;
		start = end + 1;
	}



	errno = ENOENT;
	return NULL;
}


void dup012(int fd) {
	dup2(fd, 0);
	dup2(fd, 1);
	dup2(fd, 2);
	if (fd > 2) close(fd);
}

void execute(int fd, char *path, char **argv, char **env) {

	int ok;
	int err_fd = fcntl(STDERR_FILENO, F_DUPFD_CLOEXEC, 0);

	// ok = 0; dup012(fd);
	ok = login_tty(fd);
	if (ok < 0) {
		dprintf(err_fd, "%s: login_tty: %s\n",
			getprogname(), strerror(errno)
		);
		_exit(EX_OSERR);
	}
	execve(path, argv, env);

	dprintf(err_fd, "%s: execve %s: %s\n",
		getprogname(), path, strerror(errno)
	);

	_exit(EX_OSERR);
}


pid_t child_pid;
int pty_fd;
void sig_handler(int sig, siginfo_t *info, void *context) {

	if (sig == SIGINFO || sig == SIGUSR1) {
		int rlen, wlen;
		rlen = wlen = 0;

		if (pty_fd > 0) {
			char buffer[128];
			int n,x;

			ioctl(pty_fd, TIOCOUTQ, &wlen);
			ioctl(pty_fd, FIONREAD, &rlen);

			if (rlen > 9999) rlen = 9999;
			if (wlen > 9999) wlen = 9999;

			memcpy(buffer, "child pid:        read queue:        write queue:        \n", 58);


			n = 16;
			x = child_pid;
			do {
				buffer[n--] = '0' + (x %10);
				x /= 10;
			} while(x);

			n = 35;
			x = rlen;
			do {
				buffer[n--] = '0' + (x %10);
				x /= 10;
			} while(x);

			n = 55;
			x = wlen;
			do {
				buffer[n--] = '0' + (x %10);
				x /= 10;
			} while(x);

			write(STDERR_FILENO, buffer, 58);

		}

		return;
	}
	if (sig == SIGHUP || sig == SIGINT || sig == SIGTERM) {
		/* pass to child */
		if (child_pid >= 0) {
			kill(child_pid, sig);
		}
		struct sigaction sa;
		memset(&sa, 0, sizeof(sa));
		sigemptyset(&sa.sa_mask);
		sa.sa_handler = SIG_DFL;
		sigaction(sig, &sa, NULL);
		kill(getpid(), sig);
		_exit(1);
	}

}

int main(int argc, char **argv) {

	int c;
	int fd;
	pid_t pid;
	int ok, i;
	char *pty;
	char *term = "vt100";
	char *path = NULL;


	struct winsize ws = { 24, 80, 0, 0 };
	struct termios tios;
	struct sigaction sa;


	char *env[10];
	int flag_w = 0;
	// int flag_i = 0;
	int flag_f = 0;
	int flag_r = 0;
	int flag_v = 0;


	while ((c = getopt(argc, argv, "T:rwhv")) != -1) {
		switch(c) {
			// case 'f': flag_f = 1; break;
			case 'r': flag_r = 1; break;
			case 'w': flag_w = 1; break;
			case 'v': flag_v = 1; break;
			case 'h': usage(0);
			case 'T':
				term = optarg;
				break;

			default:
				exit(EX_USAGE);
		}
	}

	argc -= optind;
	argv += optind;

	// pty [optional command]

	if (argc < 1) {
		usage(EX_USAGE);
	}


	/* n.b. - with nonblock, fd can close before all data sent */
	pty = argv[0];
	fd = open(pty, O_RDWR | /* O_NONBLOCK | */ O_CLOEXEC);
	if (fd < 0) {
		err(EX_NOINPUT, "open %s", pty);
	}
	pty_fd = fd;

	--argc;
	++argv;


    memset(&tios, 0, sizeof(tios));
    memcpy(tios.c_cc, ttydefchars, sizeof(ttydefchars));
    if (flag_r) {
    	cfmakeraw(&tios);
    } else {
	    tios.c_oflag = TTYDEF_OFLAG;
	    tios.c_lflag = TTYDEF_LFLAG;
	    tios.c_iflag = TTYDEF_IFLAG;
	    tios.c_cflag = TTYDEF_CFLAG;
	}
    tios.c_ispeed = tios.c_ospeed = B9600;


	/* verify it's pty? */

	ok = tcsetattr(fd, TCSAFLUSH, &tios);
	ok = ioctl(fd, TIOCSWINSZ, (void *)&ws);


	/* todo - option to retain environment? */
	i = 0;
	env[i++] = "LANG=C";
	env[i++] = xsprintf("TERM=%s", term);
	env[i++] = "COLUMNS=80";
	env[i++] = "LINES=24";
	if (argc) {
		char *cp;

		cp = getenv("HOME");
		if (cp) {
			env[i++] = xsprintf("HOME=%s", cp);
		}
	}
	env[i] = 0;


	if (argc) {
		path = findexe(argv[0]);
		if (!path) {
			errx(EX_OSERR, "Unable to find %s", argv[0]);
		}
		argv[0] = basename(argv[0]);
	} else {
		/* -p: don't discard environment */
		static char *args[] = {
			"login",
			"-pf",
			"",
			NULL
		};
		char *login;

		login = getlogin();
		if (!login) {
			errx(EX_OSERR, "getlogin() failed.");
		}

		path = "/usr/bin/login";
		args[2] = login;
		argv = args;
	}

	/* n.b. - login_tty will fail unless root :/ */
	if (flag_f) {
		/* foreground */
		execute(fd, path, argv, env);
		exit(0);
	}

	pid = fork();
	if (pid < 0) {
		close(fd);
		err(EX_OSERR, "fork");
	}
	if (!pid) {
		/* child */

		execute(fd, path, argv, env);
	}
	child_pid = pid;

	memset(&sa, 0, sizeof(sa));
	sa.sa_flags = SA_SIGINFO | SA_RESTART;
	sa.sa_sigaction = sig_handler;
	sigfillset(&sa.sa_mask);

	sigaction(SIGINFO, &sa, NULL);
	sigaction(SIGUSR1, &sa, NULL);
	sigaction(SIGHUP, &sa, NULL);
	sigaction(SIGINT, &sa, NULL);
	sigaction(SIGTERM, &sa, NULL);

	/* wait for the child so data isn't lost. */
	if (!flag_w) {
		pid_t ok;
		int st;

		printf("Waiting on child %d\n", (int)pid);

		for(;;) {
			ok = waitpid(pid, &st, 0);
			if (ok < 0) {
				if (errno == EINTR) {
					continue;
				}
				warn("waitpid");
				break;
			}
			child_pid = -1;
			if (WIFEXITED(st) && WEXITSTATUS(st)) {
				printf("Exit status: %d\n", WEXITSTATUS(st));
			}
			if (WIFSIGNALED(st)) {
				printf("Exit signal: %s\n", strsignal(WTERMSIG(st)));
			}
			break;
		}
		// flush discards data.
		//ok = tcflush(fd, TCIOFLUSH);
		ok = tcdrain(fd);
	}

	close(fd);
	return 0;
}
