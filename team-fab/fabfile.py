from fabric.api import env, run, sudo, settings, task
from fabric.network import prompt_for_password
import keyring

env.hosts = ['127.0.0.1']
env.key_filename = ['/Users/ryo/Dropbox/team-fab/.vagrant/machines/default/virtualbox/private_key']
env.user = 'vagrant'
env.port = 2222

@task
def vagrant_run():
    """exec whoami: user vagrant"""
    run('whoami')

@task
def root_run():
    """exec whoami: user root"""
    sudo('whoami')

@task
def fab_run():
    """exec whoami: user fab"""
    run_with('whoami', 'fab')

@task
def fab_run_with_password():
    run_someuser_with_password('whoami', 'fab', 'vagrant', 'team-fab')

def run_with(command, user):
    run('echo "%(command)s" | sudo su - %(user)s' % locals())

def run_someuser_with_password(command, exec_user, login_user, keyring_key):
    password = keyring.get_password(keyring_key, login_user)

    if password is None:
        password = prompt_for_password('[Keyring] Password for %s' % login_user)
        keyring.set_password(keyring_key, login_user, password)

    with settings(prompts = {'[sudo] password for %s: ' % login_user: password}):
        run_with(command, exec_user)
