yum install -y wget

cd /tmp

wget http://www.java.net/download/java/jdk9/archive/108/binaries/jdk-9-ea+108_linux-x64_bin.tar.gz

tar xfvz jdk-9-ea+108_linux-x64_bin.tar.gz

wget https://adopt-openjdk.ci.cloudbees.com/view/OpenJDK/job/langtools-1.9-linux-x86_64-kulla-dev/lastBuild/artifact/kulla--20160801005840.jar

echo "alias jshell='/tmp/jdk-9/bin/java -jar /tmp/kulla--20160801005840.jar'" > ~vagrant/.bashrc
