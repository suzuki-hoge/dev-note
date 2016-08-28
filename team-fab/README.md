実践Fabric

# 準備
## お断り
とりあえず動かしてみたよ、というくらいの人を想定しています
実際に仕事で使ってはまったことや便利だったことを2つ紹介するつもり

## 環境
           | version
:--        | :--    
Python     | 2.7.5  
Fabric     | 1.10.1 
Paramiko   | 1.15.2 
Vagrant    | 1.8.1  
VirtualBox | 4.3.16 

適当なssh先として、vagrantを使うよ
また、実行コマンドは何でも良いので`whoami`を使うよ

## 登場ユーザ
user    |                                                      
:--     | :--                                                  
vagrant | runコマンドの評価用 vagrantのデフォルトログインユーザ
root    | sudoコマンドの評価用 デフォルトではパスワードは不要  
fab     | sudoコマンドの評価用 適当に用意する                  

## vagrant環境に接続する
```Ruby:Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider :virtualbox do |vbox|
    vbox.name = 'team-fab'
  end
  
  config.vm.box = 'CentOS_6.5_x86_64'
  config.vm.box_url = 'https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box'
end
```

`ssh-config`でfabricに埋め込むための情報をvagrantに教えてもらうことが出来るぞ

```
$ vagrant ssh-config

Host default
HostName 127.0.0.1
User vagrant
Port 2222
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
PasswordAuthentication no
IdentityFile "xxx/team-fab/.vagrant/machines/default/virtualbox/private_key"
IdentitiesOnly yes
LogLevel FATAL
```

接続設定はこんな感じになった

```Python:fabfile.py
from fabric.api import env

env.hosts = ['127.0.0.1']
env.key_filename = ['xxx/team-fab/.vagrant/machines/default/virtualbox/private_key']
env.user = 'vagrant'
env.port = 2222
```

# 任意のユーザで実行する
## vagrantユーザ
特記する様なことはないかな、`run()`するだけだ

```Python:fabfile.py
from fabric.api import run

def vagrant_run():
    run('whoami')
```

```
$ fab vagrant_run

[127.0.0.1] Executing task 'vagrant_run'
[127.0.0.1] run: whoami
[127.0.0.1] out: vagrant
```

## rootユーザ
こちらも`sudo()`を使うだけ

```Python:fabfile.py
from fabric.api import sudo

def root_run():
    sudo('whoami')
```

```
$ fab root_run 

[127.0.0.1] Executing task 'root_run'
[127.0.0.1] sudo: whoami
[127.0.0.1] out: root
```

## fabユーザ
まずvagrantで立てたマシンにsshして、rootユーザで以下を実行する
`useradd fab`

rootではないユーザで実行する方法として、`echo xxx`をパイプで`sudo ...`に渡すという方法を試してみた

```Python:fabfile.py
from fabric.api import run

def fab_run():
    run('echo "whoami" | sudo su - fab')
```

```
$ fab fab_run                                 

[127.0.0.1] Executing task 'fab_run'
[127.0.0.1] run: echo "whoami" | sudo su - fab
[127.0.0.1] out: fab                            # fabって出てる！
[127.0.0.1] out: 
```

使いやすいかなと思い、`run_with`というのを作ってみたよ

```Python:fabfile.py
from fabric.api import run

def fab_run():
    run_with('whoami', 'fab')

def run_with(command, user):
    run('echo "%(command)s" | sudo su - %(user)s' % locals())
```

# パスワードプロンプトで止まらない様にする
## rootユーザ（パスワードを求められる場合）
まず同じくvagrant sshをして、以下を実行する
`echo "vagrant ALL=(ALL)ALL" >> /etc/sudoers`

こうするとさっき実行した`root_run`が途中で止まり、パスワード入力を求めてくる様になる

```
$ fab root_run 

[127.0.0.1] Executing task 'root_run'
[127.0.0.1] sudo: whoami
[127.0.0.1] out: sudo password:          # ここ 入力するまで進まない

[127.0.0.1] out: root
[127.0.0.1] out: 
```

### keyring
keyringというモジュールがあるらしい
OSのキー管理アプリを使ってパスワードの保存と参照が出来る様だ

これだけでインストールできるぞ！

```
pip install keyring
```

早速REPLで試してみた

```Python:REPL
>>> import keyring

>>> keyring.get_password('password-key', 'password-user') # 何も出力されない

>>> keyring.set_password('password-key', 'password-user', 'pasword1234')

>>> keyring.get_password('password-key', 'password-user') # 保存されてる！
u'pasword1234'
```

### prompts
fabricのenvにpromptsという属性があるらしい

> prompts
> デフォルト: {}

> prompts 辞書はユーザーが対話式のプロンプトをコントロールできるようにします。
> この辞書内のキーがコマンドの標準出力ストリーム内に見つかれば、Fabricは自動的に対応する辞書の値を応答します。

> バージョン 1.9 で追加.

すごい！要は事前にプロンプトがわかっていれば任意の値をfabricに入力させることが出来るってことだ！
ってことは、別にパスワードに限らずyes/noとかにも使えるっぽいね

```Python:fabfile.py
from fabric.api import settings

def fab_run_with_password():
    with settings(prompts = {'[sudo] password for vagrant: ': 'vagrant'}):
        run('echo "whoami" | sudo su - fab')
```
（補足：`settings`は部分的に`env`を書き換えるもの）

```
$ fab fab_run_with_password 

[127.0.0.1] Executing task 'fab_run_with_password'
[127.0.0.1] run: echo "whoami" | sudo su - fab
[127.0.0.1] out: [sudo] password for vagrant:     # ここで止まらない！
[127.0.0.1] out: fab
```

ちなみに、vagrant内で例えば以下のコマンドを実行したときに出るプロンプトと完全一致しなければならない
（vagrant:の直後に半角スペースがあると気づかずにすごいハマった...）

```
[vagrant@vagrant-centos65 ~]$ sudo su - fab
[sudo] password for vagrant: 
```

## keyringとpromptsを両方使い、初回以降はパスワード入力を求められなくする
こんな風になったよ

```Python:fabfile.py
import keyring
from fabric.network import prompt_for_password
from fabric.api import settings

def run_someuser_with_password(command, exec_user, login_user, keyring_key):
    password = keyring.get_password(keyring_key, login_user)                       # keyringからパスワードを取得

    if password is None:
        password = prompt_for_password('[Keyring] Password for %s' % login_user)   # keyringから取得できない場合はプロンプトを出して聞く
        keyring.set_password(keyring_key, login_user, password)

    with settings(prompts = {'[sudo] password for %s: ' % login_user: password}):  # 完全に一致するプロンプトが出たら、keyringから取得した値を使う
        run_with(command, exec_user)

def fab_run_with_password():
    run_someuser_with_password('whoami', 'fab', 'vagrant', 'team-fab')
```

```
$ fab fab_run_with_password

[127.0.0.1] Executing task 'run_fab_with_password'
[Keyring] Password for vagrant:                     # keyringのために出力したプロンプト 初回はここで止まる
[127.0.0.1] run: echo "whoami" | sudo su - fab
[127.0.0.1] out: [sudo] password for vagrant:       # ここは初回から通過できる
[127.0.0.1] out: fab
[127.0.0.1] out: 


$ fab run_fab_with_password

[127.0.0.1] Executing task 'run_fab_with_password'
[127.0.0.1] run: echo "whoami" | sudo su - fab
[127.0.0.1] out: [sudo] password for vagrant:       # 2回目以降は[Keyring]プロンプトは出ないし、当然ここも通過できる
[127.0.0.1] out: fab
[127.0.0.1] out: 
```


# documentやlist
## fab -l
```
$ fab -l
Available commands:

    fab_run
    prompt_for_password         Prompts for and returns a new password if required; otherwise, returns
    root_run
    run_fab_with_password
    run_someuser_with_password
    run_with
    vagrant_run
```
`prompt_for_password`, `run_with`, `run_someuser_with_password`はユーザに叩かせるつもりはない

```Python:fabfile.py
@task
def vagrant_run():
    run('whoami')
```

```
$ fab -l
Available commands:

    fab_run
    root_run
    run_fab_with_password
    vagrant_run
```

## document
`prompt_for_password`になにやら説明が出ている

```Python:REPL
@task
def vagrant_run():
    """exec whoami: user vagrant"""
    run('whoami')
```

```
$ fab -l
Available commands:

    fab_run                exec whoami: user fab
    root_run               exec whoami: user root
    run_fab_with_password  exec whoami with password prompt (first time only): user fab
    vagrant_run            exec whoami: user vagrant
```
インパラとかをちゃんと書いてあげると、とりあえず`fab -l`すれば使えるのでとても親切なツールになる
動的にも
