Oracle完整卸载步骤：

---

### 1. 停止 Oracle 服务
首先，确保所有 Oracle 服务已停止，防止在卸载过程中出现问题。

```bash
# 停止 Oracle 数据库实例
su - oracle
sqlplus / as sysdba
shutdown immediate;
exit;

# 停止相关的 Oracle 服务
sudo service oracle-xe stop      # 如果使用 Oracle XE
sudo service dbora stop         # 如果使用 Oracle DB
```

如果 Oracle 监听器或数据库实例未正常停止，可以使用 `ps` 命令查找并强制停止：

```bash
ps -ef | grep ora_
kill -9 <PID>  # 使用 oracle 进程的 PID
```

### 2. 删除 Oracle 软件及数据库文件
进入您安装 Oracle 数据库时指定的 `ORACLE_BASE` 和 `ORACLE_HOME` 目录，然后删除相关文件和目录。

```bash
# 删除 Oracle Home 目录
sudo rm -rf /app/oracle/product/11.2.0/db_1  # 根据实际路径调整

# 删除数据文件目录
sudo rm -rf /app/oracle/oradata

# 删除 Oracle 安装目录
sudo rm -rf /app/oraInventory
```

### 3. 删除 Oracle 用户和组
删除安装过程中创建的 Oracle 用户和组。

```bash
# 删除 Oracle 用户
sudo userdel -r oracle

# 删除 Oracle 用户组
sudo groupdel oinstall
sudo groupdel dba
```

### 4. 删除 Oracle 环境变量
Oracle 安装过程中通常会修改用户的 `.bash_profile` 或 `.bashrc`，您需要删除其中的环境变量设置。

```bash
# 编辑 .bash_profile 删除与 Oracle 相关的行
sudo vi /home/oracle/.bash_profile
# 删除以下环境变量配置
export ORACLE_BASE=/app/oracle
export ORACLE_HOME=/app/oracle/product/11.2.0/db_1
export ORACLE_SID=orcl
export PATH=$PATH:$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
```

### 5. 清理系统内核参数和限制
删除先前配置的内核参数和系统限制。

```bash
# 编辑 /etc/sysctl.conf，删除与 Oracle 相关的配置
sudo vi /etc/sysctl.conf
# 删除以下行
# fs.aio-max-nr = 1048576
# fs.file-max = 6815744
# kernel.shmall = 2097152
# kernel.shmmax = 536870912
# kernel.shmmni = 4096
# kernel.sem = 250 32000 100 128
# net.ipv4.ip_local_port_range = 9000 65500
# net.core.rmem_default = 262144
# net.core.rmem_max = 4194304
# net.core.wmem_default = 262144
# net.core.wmem_max = 1048586

# 重新加载 sysctl 配置
sudo sysctl -p
```

删除与 Oracle 用户相关的限制配置：

```bash
# 编辑 /etc/security/limits.conf，删除与 Oracle 相关的行
sudo vi /etc/security/limits.conf
# 删除以下行
# oracle soft nofile 1024
# oracle hard nofile 65536
# oracle soft nproc 16384
# oracle hard nproc 16384
# oracle soft stack 10240
# oracle hard stack 32768
```

### 6. 清理 `/etc/oraInst.loc`
删除记录 Oracle 安装位置和产品清单的配置文件。

```bash
# 删除 oraInst.loc 文件
sudo rm -f /etc/oraInst.loc
```

### 7. 删除 Oracle 安装文件和响应文件
删除 Oracle 安装过程中创建的临时文件。

```bash
# 删除临时安装文件
sudo rm -rf /tmp/oracle_install
sudo rm -rf /tmp/db_install.rsp
```

### 8. 删除防火墙规则（如果配置了）
如果您配置了防火墙规则，允许 Oracle 的监听端口（例如 1521），可以删除这些规则。

```bash
# 删除防火墙规则
sudo firewall-cmd --permanent --remove-port=1521/tcp
sudo firewall-cmd --reload
```

### 9. 删除数据库实例及其他配置文件
删除 Oracle 数据库相关的所有配置文件和实例文件。

```bash
# 删除 Oracle 数据库实例配置文件
sudo rm -rf /var/opt/oracle

# 删除启动脚本
sudo rm -rf /etc/init.d/dbora
sudo rm -rf /etc/init.d/oracledb
```

### 10. 删除安装日志和临时文件
如果您不需要保留安装过程中的日志文件，可以删除它们。

```bash
# 删除安装日志和临时文件
sudo rm -rf /tmp/OraInstall*
sudo rm -rf /tmp/installActions*
```

### 11. 检查 Oracle 是否已完全删除
检查是否有 Oracle 相关的进程仍在运行，确保完全卸载。

```bash
# 查看是否还有 Oracle 进程
ps -ef | grep oracle
```

如果没有进程返回，说明 Oracle 已经完全卸载。

### 总结
通过上述步骤，您可以彻底卸载 Oracle 11g 数据库及其所有相关文件、用户、配置和服务，确保清理干净的环境。请在执行过程中确认要删除的内容，以免误删其他重要文件。
