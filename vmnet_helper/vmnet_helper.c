/* vmnet helper */
/* because it needs root permissions ... sigh */

/*
 * basicly... run as root, read messages from stdin, write to stdout.
 */



#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <vmnet/vmnet.h>
#include <errno.h>
#include <err.h>


static interface_ref interface;
static uint8_t interface_mac[6];
static long interface_mtu;
static long interface_packet_size;
static vmnet_return_t interface_status;

static size_t buffer_size = 0;
static uint8_t *buffer = NULL;

enum {
	MSG_QUIT,
	MSG_STATUS,
	MSG_READ,
	MSG_WRITE
};
#define MAKE_MSG(msg, extra) (msg | ((extra) << 8))

ssize_t safe_read(void *buffer, size_t nbyte) {

	ssize_t rv;
	for(;;) {
		rv = read(STDIN_FILENO, buffer, nbyte);
		if (rv < 0) {
			if (errno == EINTR) continue;
			err(1, "read");
		}
		break;
	}
	return rv;
}


ssize_t safe_readv(const struct iovec *iov, int iovcnt) {

	ssize_t rv;
	for(;;) {
		rv = readv(STDIN_FILENO, iov, iovcnt);
		if (rv < 0) {
			if (errno == EINTR) continue;
			err(1, "readv");
		}
		break;
	}
	return rv;
}

ssize_t safe_write(const void *buffer, size_t nbyte) {

	ssize_t rv;
	for(;;) {
		rv = write(STDOUT_FILENO, buffer, nbyte);
		if (rv < 0) {
			if (errno == EINTR) continue;
			err(1, "write");
		}
		break;
	}
	return rv;
}

ssize_t safe_writev(const struct iovec *iov, int iovcnt) {

	ssize_t rv;
	for(;;) {
		rv = writev(STDOUT_FILENO, iov, iovcnt);
		if (rv < 0) {
			if (errno == EINTR) continue;
			err(1, "writev");
		}
		break;
	}
	return rv;
}


void msg_status(uint32_t size) {
	struct iovec iov[4];

	uint32_t msg = MAKE_MSG(MSG_STATUS, 6 + 4 + 4);

	iov[0].iov_len = 4;
	iov[0].iov_base = &msg;

	iov[1].iov_len = 6;
	iov[1].iov_base = interface_mac;

	iov[2].iov_len = 4;
	iov[2].iov_base = &interface_mtu;

	iov[3].iov_len = 4;
	iov[3].iov_base = &interface_packet_size;


	safe_writev(iov, 4);
}

int classify_mac(uint8_t *mac) {
	if ((mac[0] & 0x01) == 0) return 1; /* unicast */
	if (memcmp(mac, "\xff\xff\xff\xff\xff\xff", 6) == 0) return 0xff; /* broadcast */
	return 2; /* multicast */
}

void msg_read(uint32_t flags) {
	/* flag to block broadcast, multicast, etc? */

	int count = 1;
	int xfer;
	vmnet_return_t st;
	struct vmpktdesc v;
	struct iovec iov[2];

	uint32_t msg;


	for(;;) {
		int type;

		iov[0].iov_base = buffer;
		iov[0].iov_len = interface_packet_size;

		v.vm_pkt_size = interface_packet_size;
		v.vm_pkt_iov = iov;
		v.vm_pkt_iovcnt = 1;
		v.vm_flags = 0;

		count = 1;
		st = vmnet_read(interface, &v, &count);
		if (st != VMNET_SUCCESS) errx(1, "vmnet_read");

		if (count < 1) break;
		/* todo -- skip multicast messages based on flag? */
		type = classify_mac(buffer);
		if (type == 2) continue; /* multicast */
		break;
	}

	xfer = count == 1 ? (int)v.vm_pkt_size : 0;
	msg = MAKE_MSG(MSG_READ, xfer);
	iov[0].iov_len = 4;
	iov[0].iov_base = &msg;
	iov[1].iov_len = xfer;
	iov[1].iov_base = buffer;

	safe_writev(iov, count == 1 ? 2 : 1);
}


void msg_write(uint32_t size) {

	ssize_t ok;

	int count = 1;
	vmnet_return_t st;
	struct vmpktdesc v;
	struct iovec iov;
	uint32_t msg;

	if (size > interface_packet_size) errx(1, "packet too big");
	for(;;) {
		ok = safe_read(buffer, size);
		if (ok < 0) err(1,"read");
		if (ok != size) errx(1,"message truncated");
		break;
	}

	iov.iov_base = buffer;
	iov.iov_len = size;

	v.vm_pkt_size = size;
	v.vm_pkt_iov = &iov;
	v.vm_pkt_iovcnt = 1;
	v.vm_flags = 0;

	st = vmnet_write(interface, &v, &count);

	if (st != VMNET_SUCCESS) errx(1, "vmnet_write");


	msg = MAKE_MSG(MSG_WRITE, size);
	iov.iov_len = 4;
	iov.iov_base = &msg;

	safe_writev(&iov, 1);
}

/*
 * Drop privileges according to the CERT Secure C Coding Standard section
 * POS36-C
 * https://www.securecoding.cert.org/confluence/display/c/POS36-C.+Observe+correct+revocation+order+while+relinquishing+privileges
*/
static int drop_privileges(void) {
	// If we are not effectively root, don't drop privileges
	if (geteuid() != 0 && getegid() != 0) {
		return 0;
	}
	if (setgid(getgid()) == -1) {
		return -1;
	}
	if (setuid(getuid()) == -1) {
		return -1;
	}
	return 0;
}

void vmnet_start_interface_failed(void) {

    warnx("vmnet_start_interface failed");
    if (geteuid() != 0) {
        fputs(
              "\n\n"
              "\tvmnet_helper must be run as root.\n"
              "\tGo to Ample -> Preferences and Fix VMNet Permissions.\n\n"
              , stderr);
    }
    exit(1);
}

void vm_startup(void) {

	xpc_object_t dict;
	dispatch_queue_t q;
	dispatch_semaphore_t sem;


	memset(interface_mac, 0, sizeof(interface_mac));
	interface_status = 0;
	interface_mtu = 0;
	interface_packet_size = 0;

	dict = xpc_dictionary_create(NULL, NULL, 0);
	xpc_dictionary_set_uint64(dict, vmnet_operation_mode_key, VMNET_SHARED_MODE);
	sem = dispatch_semaphore_create(0);
	q = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);

	interface = vmnet_start_interface(dict, q, ^(vmnet_return_t status, xpc_object_t params){
		interface_status = status;
		if (status == VMNET_SUCCESS) {
			const char *cp;
			cp = xpc_dictionary_get_string(params, vmnet_mac_address_key);
			fprintf(stderr, "vmnet mac: %s\n", cp);
			sscanf(cp, "%hhx:%hhx:%hhx:%hhx:%hhx:%hhx",
				&interface_mac[0],
				&interface_mac[1],
				&interface_mac[2],
				&interface_mac[3],
				&interface_mac[4],
				&interface_mac[5]
			);

			interface_mtu = xpc_dictionary_get_uint64(params, vmnet_mtu_key);
			interface_packet_size =  xpc_dictionary_get_uint64(params, vmnet_max_packet_size_key);

			fprintf(stderr, "vmnet mtu: %u\n", (unsigned)interface_mtu);
			fprintf(stderr, "vmnet packet size: %u\n", (unsigned)interface_packet_size);

		}
		dispatch_semaphore_signal(sem);
	});
    if (!interface) {
        vmnet_start_interface_failed();
    }

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    
	if (interface_status == VMNET_SUCCESS) {
		buffer_size = (interface_packet_size * 2 + 1023) & ~1023;
		buffer = (uint8_t *)malloc(buffer_size);
	} else {
		if (interface) {
			vmnet_stop_interface(interface, q, ^(vmnet_return_t status){
				dispatch_semaphore_signal(sem);
			});
			dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
			interface = NULL;
		}
        vmnet_start_interface_failed();
	}

	dispatch_release(sem);
	xpc_release(dict);
	drop_privileges();
}

void vm_shutdown(void) {

	dispatch_queue_t q;
	dispatch_semaphore_t sem;


	if (interface) {
		sem = dispatch_semaphore_create(0);
		q = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);

		vmnet_stop_interface(interface, q, ^(vmnet_return_t status){
			dispatch_semaphore_signal(sem);
		});
		dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
		dispatch_release(sem);

		interface = NULL;
		interface_status = 0;
	}
	free(buffer);
	buffer = NULL;
	buffer_size = 0;

}

int main(int argc, char **argv) {


	uint32_t msg;
	uint32_t extra;
	ssize_t ok;


	vm_startup();

	for(;;) {
		ok = safe_read(&msg, 4);
		if (ok == 0) break;
		if (ok != 4) errx(1,"read msg");

		extra = msg >> 8;
		msg = msg & 0xff;

		switch(msg) {
			case MSG_STATUS:
				msg_status(extra);
				break;
			case MSG_QUIT:
				vm_shutdown();
				exit(0);
			case MSG_READ:
				msg_read(extra);
				break;
			case MSG_WRITE:
				msg_write(extra);
				break;
		}
	}

	vm_shutdown();
	exit(0);
}
