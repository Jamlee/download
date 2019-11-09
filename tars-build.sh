# 修改docker配置
sudo cp /lib/systemd/system/docker.service /etc/systemd/system  \
   && sudo sed -i 's/\ -H\ fd:\/\// -H\ unix:\/\/\/var\/run\/docker.sock -H tcp:\/\/0.0.0.0\ /g' /etc/systemd/system/docker.service \
   && sduo systemctl daemon-reload && sudo service docker restart

# 写入dockerfile
cat <<-EOF >Dockerfile
FROM centos:7.5.1804 as builder

ENV DOCKER_HOST="tcp://0.0.0.0:2375"
RUN curl -s -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
RUN sed  -i 's/enabled\=1/enabled\=0/g' /etc/yum/pluginconf.d/fastestmirror.conf \
   && sed  -i 's/enabled\=1/enabled\=0/g' /etc/yum/pluginconf.d/ovl.conf \
   && yum makecache
RUN yum -y install git
RUN mkdir -p /usr/local/tars/cpp/deploy && git clone https://github.com/TarsCloud/TarsWeb.git  /usr/local/tars/cpp/deploy/web
RUN mkdir -p /app && git clone https://github.com/TarsCloud/Tars.git --recursive /app/Tars


RUN rpm --rebuilddb && yum -y install wget make gcc gcc-c++ cmake yasm glibc-devel flex bison ncurses-devel zlib-devel autoconf net-tools
RUN wget -i -c http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm \
   && yum -y install mysql57-community-release-el7-10.noarch.rpm \
   && yum -y install  mysql-devel mysql-community-client
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN yum install docker-ce-cli  -y
RUN mkdir /usr/local/mysql && ln -sf /lib64/mysql /usr/local/mysql/lib && ln -sf /usr/include/mysql  /usr/local/mysql/include

# compile tars
RUN cd /app/Tars/framework/build && ./build.sh prepare && ./build.sh all && ./build.sh install
RUN cd /usr/local/tars/cpp/deploy && sh docker.sh v1
EOF

# 开始构建
docker build --network host -t tar:build .
