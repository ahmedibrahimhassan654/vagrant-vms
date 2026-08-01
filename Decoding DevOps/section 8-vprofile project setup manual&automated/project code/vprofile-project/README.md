# vProfile — Multi‑Tier Java Web Application on Virtualized Infrastructure

A production‑grade, container‑free DevOps project demonstrating the full lifecycle of a multi‑tier Java web application — from local VM provisioning through CI/CD pipeline automation.

---

## 1. Business Context

Organisations that run legacy Java monoliths still need a reliable, repeatable way to spin up identical staging and production environments. Manual server setup is slow, brittle, and impossible to audit at scale.

**vProfile** solves this by:

- Defining every piece of infrastructure as code (Vagrant + Ansible + Jenkins).
- Splitting the stack into independent tiers so each service can be scaled, monitored, and updated separately.
- Building a zero‑touch CI/CD pipeline that enforces code quality, runs automated tests, and publishes deployable artifacts — mirroring what a real enterprise delivery team does.

The application itself is a user‑profile management portal (registration, login, search, image upload, async messaging) that exercises every layer of the stack.

---

## 2. Architecture

```
User Browser
     │
     ▼
┌──────────────────────────────────────────────────────────┐
│  web01 (Nginx)          Ubuntu 22.04     192.168.56.11   │
│  Reverse proxy → app01:8080                              │
└──────────────────────────┬───────────────────────────────┘
                           │
     ┌─────────────────────▼─────────────────────────┐
     │  app01 (Tomcat 10)  CentOS 9   192.168.56.12  │
     │  vprofile-v2.war    Java 17 / Maven 3.9       │
     └──┬──────────────┬──────────────┬──────────────┘
        │              │              │
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ db01         │ │ mc01         │ │ rmq01        │
│ MariaDB      │ │ Memcached    │ │ RabbitMQ     │
│ CentOS 9     │ │ CentOS 9     │ │ CentOS 9     │
│ .56.15:3306  │ │ .56.14:11211 │ │ .56.13:5672  │
└──────────────┘ └──────────────┘ └──────────────┘
```

**Five‑tier separation** — each service runs on its own VM, identical to how it would be deployed on AWS EC2 / Azure VM / GCE instances.

---

## 3. Technology Stack & Rationale

### Application Layer

| Technology | Version | Why |
|---|---|---|
| **Java** | 17 LTS | Long‑term support, broad ecosystem |
| **Spring MVC + Security** | 6.x | Industry‑standard enterprise framework |
| **Spring Data JPA / Hibernate** | 6.x / 7.x | ORM that abstracts database vendor differences |
| **JSP + JSTL** | Jakarta EE 10 | Mature server‑side templating |
| **Maven** | 3.9 | Declarative build, dependency management, plugin ecosystem |
| **Logback + Log4j2** | 1.5 / 2.23 | Structured logging with configurable appenders |

### Infrastructure Layer

| Technology | Purpose | Why |
|---|---|---|
| **Vagrant** | Local VM orchestration | Single `vagrant up` reproduces the entire topology — no shared staging server needed |
| **VirtualBox** | Hypervisor | Free, cross‑platform, well‑supported by Vagrant |
| **Ansible** | Configuration management | Agentless, YAML‑based, idempotent — pushes Tomcat & WAR deployment to production nodes |
| **Jenkins** | CI/CD orchestration | Declarative pipeline with quality‑gate enforcement |
| **SonarQube** | Static analysis & quality gate | Blocks merges that degrade code quality |
| **Nexus Repository** | Artifact storage | Single source of truth for deployable WARs |

### Service Layer

| Service | Role | Key Port |
|---|---|---|
| **Nginx** | Reverse proxy + static file serving | 80 |
| **Apache Tomcat** | Servlet container hosting the WAR | 8080 |
| **MariaDB** | Relational database (user accounts, roles) | 3306 |
| **Memcached** | In‑memory key‑value cache (reduces DB load) | 11211 |
| **RabbitMQ** | Asynchronous message broker | 5672 |
| **Elasticsearch** | Full‑text profile search (external service) | 9300 |

---

## 4. Infrastructure Topology

| VM | Hostname | OS | IP Address | Memory | Service |
|---|---|---|---|---|---|
| web01 | web01 | Ubuntu 22.04 | 192.168.56.11 | 800 MB | Nginx |
| app01 | app01 | CentOS Stream 9 | 192.168.56.12 | 1024 MB | Tomcat 10 |
| rmq01 | rmq01 | CentOS Stream 9 | 192.168.56.13 | 600 MB | RabbitMQ |
| mc01 | mc01 | CentOS Stream 9 | 192.168.56.14 | 600 MB | Memcached |
| db01 | db01 | CentOS Stream 9 | 192.168.56.15 | 600 MB | MariaDB |

All VMs communicate over a host‑only private network (`192.168.56.0/24`). DNS resolution is handled by the `vagrant-hostmanager` plugin, which populates `/etc/hosts` on every VM automatically.

---

## 5. Replication Guide

### 5.1 Prerequisites

| Tool | Minimum Version | Install |
|---|---|---|
| VirtualBox | 7.x | https://www.virtualbox.org |
| Vagrant | 2.4+ | https://developer.hashicorp.com/vagrant/downloads |
| Git | any | `git` + Git Bash on Windows |
| RAM | 8 GB free | All 5 VMs consume ~4 GB |
| Disk | 20 GB free | CentOS + Ubuntu base boxes |

Install the required Vagrant plugin:

```bash
vagrant plugin install vagrant-hostmanager
```

If `gems.hashicorp.com` is unreachable (corporate firewall / VPN), you can comment out the `config.hostmanager.*` lines in the Vagrantfile and add host entries manually after `vagrant up`.

### 5.2 Clone the Repository

```bash
git clone https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
```

### 5.3 Option A — Fully Automated Provisioning (Recommended)

```bash
cd vagrant/Automated_provisioning_WinMacIntel
vagrant up
```

Each VM boots and runs its provisioning script automatically:

| VM | Script | What It Installs |
|---|---|---|
| db01 | `mysql.sh` | MariaDB → secured → `accounts` DB → seed data → firewall port 3306 |
| mc01 | `memcache.sh` | Memcached on 0.0.0.0:11211 → firewall ports 11211, 11111 |
| rmq01 | `rabbitmq.sh` | RabbitMQ 3.8 → user `test`/`test` → firewall port 5672 |
| app01 | `tomcat.sh` | JDK 17 → Maven 3.9 → Tomcat 10.1 → GitHub clone → `mvn install` → deploy WAR → firewalld disabled |
| web01 | `nginx.sh` | Nginx → reverse proxy config → listens on port 80 |

**Total time:** 15‑30 minutes depending on internet speed (boxes download once, cached by Vagrant).

Apple M1/M2 users: use the sibling directory `Automated_provisioning_MacOSM1/` with VMware Desktop as the provider.

### 5.4 Option B — Manual Provisioning (Learning Mode)

For understanding every component, provision each VM by hand:

```bash
cd vagrant/Manual_provisioning_WinMacIntel
vagrant up
```

Then SSH into each VM and run the commands below. **Order matters** — always start with db01, then mc01, rmq01, app01, and finally web01.

---

#### 5.4.1 db01 — MariaDB (192.168.56.15)

```bash
vagrant ssh db01
sudo -i

dnf install epel-release git zip unzip -y
dnf install mariadb-server -y
systemctl start mariadb
systemctl enable mariadb

# Secure the database
mysqladmin -u root password 'admin123'
mysql -u root -p'admin123' -e "
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
"

# Create application database and user
mysql -u root -p'admin123' -e "
  CREATE DATABASE accounts;
  GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123';
  GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost' IDENTIFIED BY 'admin123';
  FLUSH PRIVILEGES;
"

# Import seed data
git clone -b local https://github.com/hkhcoder/vprofile-project.git /tmp/vprofile-project
mysql -u root -p'admin123' accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql

# Open firewall
firewall-cmd --add-port=3306/tcp --permanent
firewall-cmd --reload
```

**Verify:** `mysql -u admin -p'admin123' accounts -e "SHOW TABLES;"` should show `role`, `user`, `user_role`.

---

#### 5.4.2 mc01 — Memcached (192.168.56.14)

```bash
vagrant ssh mc01
sudo -i

dnf install epel-release -y
dnf install memcached -y

# Bind to all interfaces (CRITICAL — the default binds to localhost only)
sed -i 's/OPTIONS=".*"/OPTIONS="-l 0.0.0.0"/' /etc/sysconfig/memcached

systemctl start memcached
systemctl enable memcached

# Open firewall (TCP for client connections, UDP for stats)
firewall-cmd --add-port=11211/tcp --permanent
firewall-cmd --add-port=11111/udp --permanent
firewall-cmd --reload
```

> **Common pitfall:** If `OPTIONS` contains `-l 0.0.0.0,::1`, the trailing `,::1` makes it an invalid IP address. Use `sed -i 's/OPTIONS="-l 0.0.0.0,::1"/OPTIONS="-l 0.0.0.0"/' /etc/sysconfig/memcached` to fix.

**Verify:** `systemctl status memcached` should show `active (running)`.

---

#### 5.4.3 rmq01 — RabbitMQ (192.168.56.13)

```bash
vagrant ssh rmq01
sudo -i

yum install epel-release wget -y
rpm -Uvh https://packagecloud.io/rabbitmq/rabbitmq-server/packages/el/9/rabbitmq-server-3.12.14-1.el9.noarch.rpm

systemctl start rabbitmq-server
systemctl enable rabbitmq-server

# Allow remote connections (guest user is restricted to localhost by default)
rabbitmqctl add_user test test
rabbitmqctl set_user_tags test administrator
rabbitmqctl set_permissions -p / test ".*" ".*" ".*"

# Open firewall
firewall-cmd --add-port=5672/tcp --permanent
firewall-cmd --reload
```

**Verify:** `rabbitmqctl list_users` should show both `guest` and `test`.

---

#### 5.4.4 app01 — Tomcat 10 (192.168.56.12)

```bash
vagrant ssh app01
sudo -i

# Install JDK 17 and Maven
dnf install java-17-openjdk java-17-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/jre-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Download and extract Maven 3.9
wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
tar -xzf apache-maven-3.9.9-bin.tar.gz -C /usr/local/
ln -s /usr/local/apache-maven-3.9.9 /usr/local/maven3.9
echo 'export M2_HOME=/usr/local/maven3.9' >> ~/.bashrc
echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Download and install Tomcat 10
useradd -r -s /sbin/nologin tomcat
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.26/bin/apache-tomcat-10.1.26.tar.gz
tar -xzf apache-tomcat-10.1.26.tar.gz -C /usr/local/
ln -s /usr/local/apache-tomcat-10.1.26 /usr/local/tomcat
chown -R tomcat:tomcat /usr/local/tomcat /usr/local/apache-tomcat-10.1.26

# Create systemd unit for Tomcat
cat > /etc/systemd/system/tomcat.service << 'EOF'
[Unit]
Description=Tomcat Application Server
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=/usr/lib/jvm/jre-17-openjdk
Environment=CATALINA_PID=/usr/local/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/usr/local/tomcat
Environment=CATALINA_BASE=/usr/local/tomcat
ExecStart=/usr/local/tomcat/bin/startup.sh
ExecStop=/usr/local/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

# Clone project and build the WAR
git clone -b local https://github.com/hkhcoder/vprofile-project.git /tmp/vprofile-project
cd /tmp/vprofile-project
export MAVEN_OPTS="-Xmx512m"
mvn install

# Deploy the WAR
systemctl stop tomcat
rm -rf /usr/local/tomcat/webapps/ROOT*
cp target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
systemctl start tomcat

# Disable firewalld (internal-only network, not needed between VMs)
systemctl stop firewalld
systemctl disable firewalld
```

> **Memory note:** If `mvn install` fails with `Java heap space`, the VM only has 800‑1024 MB RAM. Bump it in the Vagrantfile (`vb.memory = "1600"`) and `vagrant reload app01`, or set `MAVEN_OPTS="-Xmx512m"` before building.

**Verify:** `curl -s http://localhost:8080` should return the login page HTML.

---

#### 5.4.5 web01 — Nginx (192.168.56.11)

```bash
vagrant ssh web01
sudo -i

apt update
apt install nginx -y

# Create reverse proxy configuration
cat > /etc/nginx/sites-available/vproapp << 'EOF'
upstream vproapp {
    server app01:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://vproapp;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
systemctl restart nginx
```

**Verify:** `curl -s http://localhost` should return the login page HTML from Tomcat.

---

### 5.5 Final Verification

1. Open a browser on the host machine and navigate to **http://192.168.56.11**
2. Login with the seeded credentials: **`admin_vp`** / **`admin_vp`**
3. Confirm: user list loads, registration works, new profiles persist across page refreshes (Memcached), and the RabbitMQ messaging page (`/rabbitmq`) is accessible.

---

## 6. CI/CD Pipeline (Jenkins)

The project includes a **declarative Jenkins pipeline** (`Jenkinsfile` at the repo root) that models a real enterprise delivery workflow.

### Pipeline Stages

| Stage | Tool | What Happens |
|---|---|---|
| **Build** | Maven | `mvn clean install -DskipTests` — compiles and packages the WAR. Artifact archived. |
| **Unit Test** | Maven + JUnit + Mockito | `mvn test` — runs all unit tests. |
| **Integration Test** | Maven | `mvn verify -DskipUnitTests` — runs integration tests. |
| **Code Analysis (Checkstyle)** | Maven Checkstyle plugin | Generates a Checkstyle report in `target/`. |
| **Code Analysis (SonarQube)** | SonarScanner | Pushes results to SonarQube server; enforces **Quality Gate** with a 10‑minute timeout. Pipeline aborts if the gate fails. |
| **Publish to Nexus** | Nexus Artifact Uploader | Uploads the WAR and POM to Nexus Repository Manager (`vprofile-release` repo). |

### Jenkins Configuration Required

- **Global Tools:** JDK 17 (`JDK17`), Maven 3.9 (`MAVEN3.9`), SonarScanner (`sonarscanner4`)
- **Server Connections:** SonarQube (`sonar-pro`), Jenkins system configuration
- **Credentials:** Nexus login (`nexuslogin` — username + password credential)
- **Plugins:** Nexus Artifact Uploader, SonarQube Scanner, Checkstyle

The pipeline demonstrates:
- **Fast feedback** — unit tests fail within seconds, not minutes.
- **Quality enforcement** — code that violates SonarQube rules never reaches Nexus.
- **Single artifact path** — every deployable binary is traceable back to a Jenkins build number.

---

## 7. Configuration Management with Ansible

The `ansible/` directory provides an alternative, agentless deployment path suitable for production use on AWS EC2, Azure VM, or on‑premise CentOS/Ubuntu servers.

```
ansible/
├── ansible.cfg              # Disables host key checking; 35s timeout
├── site.yml                 # Master playbook — imports tomcat_setup + vpro-app-setup
├── tomcat_setup.yml         # Installs JDK 8, downloads Tomcat 8.5, creates systemd unit
├── vpro-app-setup.yml       # Pulls WAR from Nexus, deploys, rewires ROOT, rollback handler
├── templates/
│   ├── application.j2       # application.properties with parameterized DB/RabbitMQ/Memcached hosts
│   └── tomcat*.j2           # Systemd / init.d service templates for CentOS 6/7, Ubuntu 14‑18
└── files/
```

**Usage flow:**

1. Define an inventory file with your target servers.
2. Set required variables: `nexusip`, `reponame`, `groupid`, `dbhost`, `db_user`, `db_password`, `mc_host`, `rmq_host`, etc.
3. Run: `ansible-playbook -i inventory site.yml`

Ansible shows how to take a locally‑built artifact from Nexus and deploy it idempotently across any number of Tomcat nodes — a pattern that scales to hundreds of servers.

---

## 8. Credentials & Ports Reference

### Database

| Key | Value |
|---|---|
| Host | 192.168.56.15:3306 |
| Root password | `admin123` |
| App user | `admin` / `admin123` |
| Database | `accounts` |

### RabbitMQ

| Key | Value |
|---|---|
| Host | 192.168.56.13:5672 |
| User | `test` / `test` |
| Virtual host | `/` |

### Memcached

| Key | Value |
|---|---|
| Host | 192.168.56.14 |
| TCP port | 11211 |
| UDP port | 11111 |

### Application Login (Seeded User)

| Key | Value |
|---|---|
| Username | `admin_vp` |
| Password | `admin_vp` |

All passwords are **hard‑coded for lab/demo purposes**. In production, these would be injected at runtime via environment variables, Vault, or a secrets manager.

---

## 9. Troubleshooting Common Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| `vagrant up` fails with `Unknown configuration section 'hostmanager'` | Plugin not installed | `vagrant plugin install vagrant-hostmanager` |
| `vagrant plugin install` times out | Corporate firewall / VPN blocking `gems.hashicorp.com` | Comment out `config.hostmanager.*` in Vagrantfile; add `/etc/hosts` entries manually after boot |
| **502 Bad Gateway** from Nginx | Tomcat not running OR firewalld blocking port 8080 on app01 | `systemctl status tomcat` on app01; `systemctl stop firewalld && systemctl disable firewalld` on app01 |
| Login page loads but credential submit fails | firewalld blocking port 3306 on db01 | `firewall-cmd --add-port=3306/tcp --permanent && firewall-cmd --reload` on db01 |
| RabbitMQ error page | User `test` / `test` not created OR firewalld blocking port 5672 | `rabbitmqctl add_user test test` (see Section 5.4.3) |
| Memcached `bind(): Cannot assign requested address` | `-l 0.0.0.0,::1` is invalid (comma‑separated addresses) | `sed -i 's/OPTIONS="-l 0.0.0.0,::1"/OPTIONS="-l 0.0.0.0"/' /etc/sysconfig/memcached` |
| Maven `Java heap space` | VM has only 800‑1024 MB RAM | Run `export MAVEN_OPTS="-Xmx512m"` before `mvn install`, or bump VM RAM to 1600 MB in Vagrantfile |

---

## 10. Portfolio Takeaways

This project demonstrates competence in the following DevOps domains:

- **Infrastructure as Code** — Vagrant provisions 5 VMs with a single command; Vagrantfiles are portable between hypervisors (VirtualBox, VMware).
- **Configuration Management** — Ansible playbooks and Jinja2 templates deploy the full stack idempotently.
- **CI/CD Pipeline Engineering** — Jenkins declarative pipeline with automated build → test → quality gate → artifact publish.
- **Service Decoupling** — Database, cache, message broker, app server, and web server each run in isolation, matching cloud‑native design patterns.
- **Security Hardening** — Database access restricted to specific hosts, Spring Security with BCrypt password hashing, RabbitMQ guest user replaced with named credentials.
- **Observability** — Structured logging (Logback + Log4j2) across all application tiers.
- **Documentation** — Every command is documented; every credential is catalogued; every failure mode has a diagnosis and fix.

---

## License

This project is created for educational purposes as part of the *Decoding DevOps* Udemy course.
