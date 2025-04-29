#!/bin/bash
# Oracle 11gR2 自动安装脚本 for CentOS 7
# 需要root权限执行

# 检查root权限
if [ "$(id -u)" != "0" ]; then
   echo "此脚本必须以root用户身份运行" 1>&2
   exit 1
fi

# 配置变量
ORACLE_VERSION="11.2.0"
ORACLE_BASE="/home/app/oracle"
ORACLE_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/db_1"
ORACLE_INV="/home/app/oraInventory"
ORACLE_PASSWORD="oracle"
ORACLE_DBNAME="orcl"
ORACLE_CHARSET="ZHS16GBK"

# 0. 安装前准备
echo "正在安装必要工具..."
yum install -y wget unzip bc binutils compat-libcap1 gcc gcc-c++ glibc glibc-devel ksh \
libaio libaio-devel libgcc libstdc++ libstdc++-devel libXi libXtst make sysstat

# 1. 系统配置
echo "配置系统参数..."

# 禁用SELinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# 配置内核参数
cat >> /etc/sysctl.conf << EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 536870912
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
EOF

sysctl -p

# 配置用户限制
cat >> /etc/security/limits.conf << EOF
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
EOF

# 2. 创建用户和组
echo "创建Oracle用户和组..."
groupadd -g 54321 oinstall
groupadd -g 54322 dba
useradd -u 54321 -g oinstall -G dba oracle
echo "${ORACLE_PASSWORD}" | passwd oracle --stdin

# 3. 创建目录结构
echo "创建Oracle目录..."
mkdir -p ${ORACLE_BASE} ${ORACLE_HOME} ${ORACLE_INV}
chown -R oracle:oinstall /home/app
chmod -R 775 /home/app

# 4. 配置环境变量
echo "配置环境变量..."
cat >> /home/oracle/.bash_profile << EOF
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_SID=${ORACLE_DBNAME}
export PATH=\$PATH:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.${ORACLE_CHARSET}
EOF

# 5. 安装文件准备（需手动下载安装包）
INSTALL_DIR="/tmp/oracle_install"
# 请将安装文件放置到指定位置（需要两个ZIP文件）
# 示例（需手动操作）：
# mv linux.x64_11gR2_*.zip ${INSTALL_DIR}

# 检查安装文件是否存在
if [ ! -f "${INSTALL_DIR}/linux.x64_11gR2_database_1of2.zip" ] || [ ! -f "${INSTALL_DIR}/linux.x64_11gR2_database_2of2.zip" ]; then
    echo "错误：找不到Oracle安装文件！"
    echo "请从Oracle官网下载以下文件并放置到${INSTALL_DIR}目录："
    echo "- linux.x64_11gR2_database_1of2.zip"
    echo "- linux.x64_11gR2_database_2of2.zip"
    exit 1
fi

# 解压安装文件
echo "解压安装文件..."
unzip -q "${INSTALL_DIR}/linux.x64_11gR2_database_1of2.zip" -d ${INSTALL_DIR}
unzip -q "${INSTALL_DIR}/linux.x64_11gR2_database_2of2.zip" -d ${INSTALL_DIR}
chown -R oracle:oinstall ${INSTALL_DIR}/database

# 6. 准备响应文件
echo "生成响应文件..."
RESPONSE_FILE="${INSTALL_DIR}/db_install.rsp"

cat > ${RESPONSE_FILE} << EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0
oracle.install.option=INSTALL_DB_SWONLY
ORACLE_HOSTNAME=oracle.server
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=${ORACLE_INV}
SELECTED_LANGUAGES=en,zh_CN
ORACLE_HOME=${ORACLE_HOME}
ORACLE_BASE=${ORACLE_BASE}
oracle.install.db.InstallEdition=EE
oracle.install.db.isCustomInstall=false
oracle.install.db.CLUSTER_NODES=
oracle.install.db.DBA_GROUP=dba
oracle.install.db.OPER_GROUP=oinstall
oracle.install.db.config.starterdb.enableSecuritySettings=true
oracle.install.db.config.starterdb.installExampleSchemas=false
oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE
oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=${ORACLE_BASE}/oradata
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
oracle.install.db.config.starterdb.globalDBName=orcl
oracle.install.db.config.starterdb.SID=orcl
oracle.install.db.config.starterdb.characterSet=ZHS16GBK
oracle.install.db.config.starterdb.password.ALL=oracle
DECLINE_SECURITY_UPDATES=true
EOF

# 7. 执行安装程序
echo "开始安装Oracle..."
su - oracle -c "${INSTALL_DIR}/database/runInstaller -silent -responseFile ${RESPONSE_FILE} -ignorePrereq"

# 等待安装完成（约需30-60分钟）
sleep 300
echo "安装进行中...请等待（此过程可能需要较长时间）"

# 8. 执行root脚本
echo "执行root脚本..."
${ORACLE_HOME}/root.sh
${ORACLE_INV}/orainstRoot.sh

# 9. 创建数据库（可选）
echo "创建数据库..."
su - oracle -c "dbca -silent -createDatabase \
 -templateName General_Purpose.dbc \
 -gdbname ${ORACLE_DBNAME} -sid ${ORACLE_DBNAME} \
 -sysPassword ${ORACLE_PASSWORD} \
 -systemPassword ${ORACLE_PASSWORD} \
 -characterSet ${ORACLE_CHARSET} \
 -totalMemory 2048 \
 -storageType FS \
 -datafileDestination ${ORACLE_BASE}/oradata \
 -emConfiguration NONE \
 -sampleSchema false"

# 10. 配置防火墙
echo "配置防火墙..."
firewall-cmd --permanent --add-port=1521/tcp
firewall-cmd --reload

echo "Oracle安装完成！"
echo "连接信息："
echo "- Host: $(hostname)"
echo "- Port: 1521"
echo "- SID: ${ORACLE_DBNAME}"
echo "- System Password: ${ORACLE_PASSWORD}"
