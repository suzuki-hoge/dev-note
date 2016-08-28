Java9のREPLをVagrantで試してみた

ローカルのファイル整理をしてたら前書いたメモが出てきたのでゆるい感じで投稿するよ

## Vagrantfile
```Ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider :virtualbox do |vbox|
    vbox.name = 'jshell'
  end
  
  config.vm.box = 'CentOS6.5'
  config.vm.box_url = 'https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box'
  
  config.vm.provision :shell, :path => 'setup.sh'
end
```

## setup.sh
```Shell
yum install -y wget

cd /tmp

wget http://download.java.net/java/jdk9/archive/108/binaries/jdk-9-ea+108_linux-x64_bin.tar.gz

tar xfz jdk-9-ea+108_linux-x64_bin.tar.gz

wget https://adopt-openjdk.ci.cloudbees.com/view/OpenJDK/job/langtools-1.9-linux-x86_64-kulla-dev/lastBuild/artifact/kulla--20160801005840.jar

echo "alias jshell='/tmp/jdk-9/bin/java -jar /tmp/kulla--20160801005840.jar'" > ~vagrant/.bashrc
```

もし`kulla--20160801005840.jar`が無かった場合は、[URLのartifact/の部分までのアドレス](https://adopt-openjdk.ci.cloudbees.com/view/OpenJDK/job/langtools-1.9-linux-x86_64-kulla-dev/lastBuild/artifact/)でJenkinsにアクセスしてビルド番号？を確認してね

## 実行
### VagrantにSSHするまで
Vagrantの出力は略

```Shell
$ ls
Vagrantfile setup.sh

$ vagrant up --provision

$ vagrant ssh
```

### jshell起動
起動時の出力は略

```Shell
% jshell
```

#### お約束
```
-> System.out.println("Hello")
Hello
```

#### Tabで補完が出来る
```
-> System.out.print
print(     printf(    println(   
```

#### 変数定義も出来るし、それらのTab補完も出来る
```
-> String serverName = "hostxxx"
|  Added variable serverName of type String with initial value "hostxxx"

-> String serverStatus = "ok"
|  Added variable serverStatus of type String with initial value "ok"

-> server
serverName     serverStatus   
```

#### 評価した値は一時変数みたいなのに入る
```
-> "java"
|  Expression value is: "java"
|    assigned to temporary variable $5 of type String

-> $5 + "9"
|  Expression value is: "java9"
|    assigned to temporary variable $6 of type String

-> $6
|  Variable $6 of type String has value "java9"
```

#### Importもできるし、してあればTabで補完できる
```
-> import java.util.stream.Stream

-> import java.util.stream.Coll
Collector    Collectors   

-> import java.util.stream.Collectors

-> Stream.of(1, 2, 3, 4, 5).filter(n -> n != 3).map(n -> n * 2).col(
collect(   

-> Stream.of(1, 2, 3, 4, 5).filter(n -> n != 3).map(n -> n * 2).collect(Coll
Collection    Collections   Collectors    

-> Stream.of(1, 2, 3, 4, 5).filter(n -> n != 3).map(n -> n * 2).collect(Collectors.toList())
|  Expression value is: [2, 4, 8, 10]
|    assigned to temporary variable $10 of type List<Integer>
```

## 感想
+ Tab補完効くのはかなり好印象
 + Pythonは効かなかった様な
 + Haskellは効くよね
 + Scalaはどうだったっけ
+ 出力がなんかいちいちうっおとしいw
 + ただ値評価しただけで長々と文が出るから、毎回「ん？例外？」って思っちゃうｗ
