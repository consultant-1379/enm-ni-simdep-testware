#!/usr/bin/python
import os, sys, paramiko, subprocess
default_keyfile = "~/.ssh/id_rsa.pub"


def run_cmd(cmd, msg, get_output = False):
    try:
        if not get_output:
            return subprocess.call(cmd, shell=True)
        else:
            pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
            pipe.communicate()
            return pipe.returncode
    except:
        print "ERROR: %s" % msg
        sys.exit(1)


def has_passwordless_access(user, server):
    rc = run_cmd("ssh -o ConnectTimeout=5 -o PreferredAuthentications=publickey -o"
                 " BatchMode=yes {0}@{1} 'hostname' > /dev/null 2>&1".format(user, server),
                 "Public key-based SSH connection test failed")

    return True if rc == 0 else False


def copy_ssh_key_to_server(server, user, passwd, key_file=None):
    # Check to see if we have access; abort if we do ###
    if has_passwordless_access(user, server):
        print "Verified passwordless publickey-based access to remote host {0} as user {1}".format(server, user)
        return 0

    if key_file is None:
        key_file = default_keyfile
    ssh_dir = os.path.expanduser("~/.ssh")
    key_file = os.path.expanduser(key_file)

    # make sure that the keyfile exists ###
    if not os.path.isdir(ssh_dir):
        print "Creating directory {0}...".format(ssh_dir)
        os.makedirs(ssh_dir)

    if not os.path.exists(key_file):
        cmd = "ssh-keygen -b 2048 -t rsa -f id_rsa -q -N \"\""
        print "Running '{0}' to create RSA public key".format(cmd)
        rc = run_cmd(cmd, "ERROR: Could not create RSA public key")
        if rc != 0:
            return rc

    with open(key_file) as kf:
        key = kf.read()

    # initialize SSH client and configure to auto-accept unknown keys ###
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    # connect to the remote host ###
    print "Connecting to remote host {0} as user {1}".format(server, user)
    ssh.connect(server, username=user, password=passwd)

    # create the .ssh dir if it doesn't already exist ###
    ssh.exec_command("bash -c 'mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys'")
    ssh.exec_command("bash -c 'echo \"%s\" >> ~/.ssh/authorized_keys'" % key)
    ssh.exec_command("bash -c 'sort < ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp'")
    ssh.exec_command("bash -c 'uniq < ~/.ssh/authorized_keys.tmp > ~/.ssh/authorized_keys'")
    ssh.exec_command("bash -c 'chmod 0644 ~/.ssh/authorized_keys'")
    ssh.exec_command("bash -c 'rm -f ~/.ssh/authorized_keys.tmp'")
    ssh.exec_command("bash -c '/sbin/restorecon ~/.ssh ~/.ssh/authorized_keys'")
    ssh.close()

    # now add the remote host's host key to our known_hosts file ###
    print "Adding remote hosts's host key to our known_hosts file..."
    run_cmd("ssh-keygen -R {0} > /dev/null 2>&1".format(server),
            "Could not remove current host key from our known_hosts file")
    run_cmd("ssh-keyscan -H {0} >> ~/.ssh/known_hosts 2> /dev/null".format(server),
            "Could not add host key to our known_hosts file")

    # verify that we're good ###
    print "Verifying passwordless publickey-based connection..."
    if has_passwordless_access(user, server):
        return 0
    else:
        return 1

# syntax: copy_ssh_key.py <server> <username> <password> [public key file] ###
if __name__ == "__main__":
    # make sure we got 5 args ###
    if len(sys.argv) < 4:
        print "\nERROR: 3 arguments required, the fourth argument is optional"
        print "syntax: copy_ssh_key.py <server> <username> <password> [public key file]\n"
        sys.exit(1)

    # if we were given a 4th argument, that is the user-specified key file ###
    if len(sys.argv) == 5:
        rc = copy_ssh_key_to_server(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        rc = copy_ssh_key_to_server(sys.argv[1], sys.argv[2], sys.argv[3])
    sys.exit(rc)

