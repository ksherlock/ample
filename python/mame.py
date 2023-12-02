
import subprocess


def run(*args):

	env = {'DYLD_FALLBACK_FRAMEWORK_PATH': '../embedded'}
	path = "../embedded/mame64"
	path = "../mame/mame-x64"

	st = subprocess.run([path, *args], capture_output=True, env=env, text=True, check=True)

	#if st.returncode != 0:
	#	print("mame error: {}".format(m))
	#	exit(1)

	return st.stdout
