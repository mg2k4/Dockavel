#!/bin/bash
set -e

# ==========================================
# Laravel Docker Server Setup Script
# Run on the server directly (manual SSH)
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/server-setup-local.sh)
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DEPLOY_USER="deploy"
PROJECT_DIR="/var/www"

print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

print_step() {
    echo -e "\n${CYAN}[$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    echo -e "${YELLOW}Usage: sudo bash server-setup-local.sh${NC}"
    exit 1
fi

# Get the actual user who called sudo
ACTUAL_USER="${SUDO_USER:-root}"

print_header "🚀 Laravel Docker Server Setup"

echo -e "${BLUE}This script will configure:${NC}"
echo -e "  • System updates"
echo -e "  • Docker + Docker Compose"
echo -e "  • Firewall UFW (ports 22, 80, 443)"
echo -e "  • Fail2Ban (SSH protection)"
echo -e "  • Deploy user: ${GREEN}${DEPLOY_USER}${NC}"
echo -e "  • Project directory: ${GREEN}${PROJECT_DIR}${NC}"
echo -e "  • SSH hardening"
echo -e "  • Automatic security updates"
echo -e ""

read -p "Continue? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Aborted."
    exit 0
fi

# Step 1: System Update
print_step "1/11" "Updating system..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
print_success "System updated"

# Step 2: Install Essential Packages
print_step "2/11" "Installing essential packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl \
    git \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    dnsutils \
    openssl \
    htop \
    tree \
    ncdu
print_success "Essential packages installed"

# Step 3: Configure Firewall
print_step "3/11" "Configuring UFW firewall..."
ufw --force disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
print_success "Firewall configured (ports: 22, 80, 443)"

# Step 4: Configure Fail2Ban
print_step "4/11" "Configuring Fail2Ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban

[sshd]
enabled = true
port = 22
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
bantime = 7200
EOF

systemctl enable fail2ban >/dev/null 2>&1
systemctl restart fail2ban
print_success "Fail2Ban configured (2h ban after 5 failed attempts)"

# Step 5: Create Deploy User
print_step "5/11" "Creating deploy user..."

if id "$DEPLOY_USER" &>/dev/null; then
    print_warning "User $DEPLOY_USER already exists"
else
    useradd -m -s /bin/bash "$DEPLOY_USER"
    # Add to sudo with NOPASSWD for Docker commands
    echo "$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose, /usr/bin/systemctl" >> /etc/sudoers.d/$DEPLOY_USER
    chmod 0440 /etc/sudoers.d/$DEPLOY_USER
    print_success "User $DEPLOY_USER created with Docker permissions"
fi

# Step 6: Setup SSH for Deploy User
print_step "6/11" "Setting up SSH for $DEPLOY_USER..."

mkdir -p /home/$DEPLOY_USER/.ssh
chmod 700 /home/$DEPLOY_USER/.ssh

# Copy SSH keys from current user
KEYS_COPIED=false
if [ "$ACTUAL_USER" != "root" ] && [ -f /home/$ACTUAL_USER/.ssh/authorized_keys ]; then
    print_info "Copying SSH keys from $ACTUAL_USER"
    cp /home/$ACTUAL_USER/.ssh/authorized_keys /home/$DEPLOY_USER/.ssh/authorized_keys
    print_success "SSH keys copied from $ACTUAL_USER"
    KEYS_COPIED=true
elif [ -f /root/.ssh/authorized_keys ]; then
    print_info "Copying SSH keys from root"
    cp /root/.ssh/authorized_keys /home/$DEPLOY_USER/.ssh/authorized_keys
    print_success "SSH keys copied from root"
    KEYS_COPIED=true
else
    touch /home/$DEPLOY_USER/.ssh/authorized_keys
fi

chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh

# Display existing keys and offer to add more
echo ""
if [ "$KEYS_COPIED" = true ]; then
    print_info "SSH key(s) currently configured for ${DEPLOY_USER}:"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    cat /home/$DEPLOY_USER/.ssh/authorized_keys
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${BLUE}If you use this key on your PC, you'll be able to connect.${NC}"
    echo -e "${YELLOW}If you use a DIFFERENT SSH key, add it now!${NC}"
else
    print_warning "No SSH keys found to copy"
fi

echo ""
read -p "Do you want to add an SSH public key from your PC? (y/n): " add_key
if [ "$add_key" == "y" ]; then
    echo -e "${BLUE}Paste your SSH public key (e.g., ssh-ed25519 AAAA... user@pc):${NC}"
    read -r user_ssh_key

    if [ -n "$user_ssh_key" ]; then
        echo "$user_ssh_key" >> /home/$DEPLOY_USER/.ssh/authorized_keys
        chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
        chown $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh/authorized_keys
        print_success "Your SSH key added"
    fi
fi

# Step 7: Install Docker
print_step "7/11" "Installing Docker..."

if command -v docker &> /dev/null; then
    print_warning "Docker already installed ($(docker --version))"
else
    # Add Docker repository
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # Add deploy user to docker group
    usermod -aG docker $DEPLOY_USER

    systemctl enable docker >/dev/null 2>&1
    systemctl start docker
    print_success "Docker installed ($(docker --version))"
fi

# Step 8: Generate SSH Key for GitHub (deploy user)
print_step "8/11" "Generating SSH key for GitHub..."

su - $DEPLOY_USER -c "
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C '${DEPLOY_USER}@$(hostname)' -f ~/.ssh/id_ed25519 -N ''
fi
" > /dev/null 2>&1

GITHUB_KEY=$(su - $DEPLOY_USER -c "cat ~/.ssh/id_ed25519.pub")
print_success "SSH key generated for GitHub"

# Step 9: Harden SSH Configuration
print_step "9/11" "Hardening SSH configuration..."

# Backup SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Remove all old directives (commented or not, with or without spaces)
sed -i '/^[[:space:]]*#*[[:space:]]*PermitRootLogin/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*PasswordAuthentication/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*PubkeyAuthentication/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*ChallengeResponseAuthentication/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*KbdInteractiveAuthentication/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*UsePAM/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*X11Forwarding/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*MaxAuthTries/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*ClientAliveInterval/d' /etc/ssh/sshd_config
sed -i '/^[[:space:]]*#*[[:space:]]*ClientAliveCountMax/d' /etc/ssh/sshd_config

# Add new security directives at the end
cat >> /etc/ssh/sshd_config << 'EOF'

# ===================================
# Security Hardening - Laravel Setup
# ===================================
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Also handle cloud-init config files that might override
if [ -d /etc/ssh/sshd_config.d ]; then
    # Disable PasswordAuthentication in cloud-init configs
    for conf_file in /etc/ssh/sshd_config.d/*.conf; do
        if [ -f "$conf_file" ]; then
            sed -i '/^[[:space:]]*#*[[:space:]]*PasswordAuthentication/d' "$conf_file"
            if grep -q "PasswordAuthentication" "$conf_file" 2>/dev/null; then
                sed -i 's/PasswordAuthentication.*/PasswordAuthentication no/' "$conf_file"
            fi
        fi
    done

    # Add hardening to cloud-init if it exists
    if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]; then
        cat >> /etc/ssh/sshd_config.d/50-cloud-init.conf << 'EOF'

# Security Hardening
PasswordAuthentication no
PermitRootLogin no
EOF
    fi
fi

# Test SSH configuration before proceeding
if ! sshd -t 2>/dev/null; then
    print_error "Error in SSH configuration!"
    print_warning "Restoring backup..."
    LATEST_BACKUP=$(ls -t /etc/ssh/sshd_config.backup.* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        cp "$LATEST_BACKUP" /etc/ssh/sshd_config
    fi
    exit 1
fi

print_success "SSH configuration prepared (not applied yet)"

# Step 10: Configure Automatic Security Updates
print_step "10/11" "Configuring automatic security updates..."

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF

print_success "Automatic security updates enabled"

# Step 11: Setup Project Directory
print_step "11/11" "Setting up project directory..."
mkdir -p $PROJECT_DIR
chown -R $DEPLOY_USER:$DEPLOY_USER $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
print_success "Project directory created: $PROJECT_DIR"

# Summary and next steps
print_header "✅ Server Configuration Complete!"

SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}Configuration applied:${NC}"
echo -e "  • Firewall:           ${GREEN}✓${NC} Active (22, 80, 443)"
echo -e "  • Fail2Ban:           ${GREEN}✓${NC} Active (SSH protection)"
echo -e "  • Docker:             ${GREEN}✓${NC} $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo -e "  • Docker Compose:     ${GREEN}✓${NC} $(docker compose version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' | head -1)"
echo -e "  • Auto-updates:       ${GREEN}✓${NC} Enabled"
echo -e "  • Deploy user:        ${GREEN}${DEPLOY_USER}${NC}"
echo -e "  • Project directory:  ${GREEN}${PROJECT_DIR}${NC}"

echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🔑 SSH KEY FOR YOUR PC (to connect as deploy@server)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"

if [ -s /home/$DEPLOY_USER/.ssh/authorized_keys ]; then
    echo -e "${BLUE}SSH key(s) configured for ${DEPLOY_USER}:${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    cat /home/$DEPLOY_USER/.ssh/authorized_keys
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${GREEN}→ If this key is on your PC, you'll be able to connect${NC}"
    echo -e "${GREEN}→ Otherwise, add your public key to: /home/deploy/.ssh/authorized_keys${NC}"
else
    echo -e "${RED}⚠ No SSH key configured!${NC}"
    echo -e "${YELLOW}You must add your public key manually:${NC}"
    echo -e "${GREEN}echo 'your-public-key' >> /home/deploy/.ssh/authorized_keys${NC}"
fi

echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🔑 SSH PUBLIC KEY TO ADD ON GITHUB${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"
echo -e "${BLUE}Add this key to GitHub so the server can clone repositories:${NC}"
echo -e "${GREEN}https://github.com/settings/keys${NC}\n"
echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}${GITHUB_KEY}${NC}"
echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}\n"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}⚠️  CRITICAL: TEST SSH CONNECTION${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${RED}BEFORE restarting SSH, test the connection!${NC}\n"
echo -e "${BLUE}1. Open a NEW terminal/session (DO NOT close this one)${NC}"
echo -e "${BLUE}2. Test the connection:${NC}"
echo -e "   ${GREEN}ssh $DEPLOY_USER@$SERVER_IP${NC}\n"
echo -e "${BLUE}3. If connection WORKS:${NC}"
echo -e "   ${GREEN}→ Type 'exit' to disconnect${NC}"
echo -e "   ${GREEN}→ Come back here and type 'yes'${NC}\n"
echo -e "${BLUE}4. If connection DOES NOT WORK:${NC}"
echo -e "   ${RED}→ Add your SSH public key manually${NC}"
echo -e "   ${YELLOW}→ Command: echo 'your-key' >> /home/deploy/.ssh/authorized_keys${NC}"
echo -e "   ${YELLOW}→ Then test the connection again${NC}\n"

read -p "Have you tested and validated SSH connection with $DEPLOY_USER? (yes/no): " ssh_tested

if [ "$ssh_tested" == "yes" ]; then
    print_info "Restarting SSH service..."
    systemctl restart sshd
    print_success "SSH hardened and restarted"

    echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 SERVER READY FOR DEPLOYMENT${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}\n"

    echo -e "${BLUE}Next steps:${NC}\n"
    echo -e "${YELLOW}1.${NC} Disconnect and reconnect as deploy:"
    echo -e "   ${GREEN}ssh $DEPLOY_USER@$SERVER_IP${NC}\n"

    echo -e "${YELLOW}2.${NC} Clone your Laravel project:"
    echo -e "   ${GREEN}cd $PROJECT_DIR${NC}"
    echo -e "   ${GREEN}git clone git@github.com:YOUR_USERNAME/YOUR_REPO.git app${NC}"
    echo -e "   ${GREEN}cd app${NC}\n"

    echo -e "${YELLOW}3.${NC} Make scripts executable:"
    echo -e "   ${GREEN}chmod +x scripts/*.sh${NC}\n"

    echo -e "${YELLOW}4.${NC} Deploy the application:"
    echo -e "   ${GREEN}./scripts/deploy.sh prod${NC}\n"

else
    print_error "SSH NOT tested - SSH hardening CANCELLED"
    echo ""
    print_warning "SSH is NOT hardened yet for your safety"
    print_info "Once your SSH connection is tested successfully, harden SSH with:"
    echo -e "\n${GREEN}sudo systemctl restart sshd${NC}\n"

    echo -e "${YELLOW}To add your SSH key manually:${NC}"
    echo -e "${GREEN}echo 'your-ssh-public-key' >> /home/deploy/.ssh/authorized_keys${NC}"
    echo -e "${GREEN}chmod 600 /home/deploy/.ssh/authorized_keys${NC}"
    echo -e "${GREEN}chown deploy:deploy /home/deploy/.ssh/authorized_keys${NC}\n"
fi

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📖 Important keys summary:${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
echo -e "${CYAN}🔑 Key for GitHub (shown above)${NC}"
echo -e "${CYAN}🔑 Key(s) for SSH deploy (shown above)${NC}\n"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
