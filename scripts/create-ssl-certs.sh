#!/bin/bash

# ==========================================
# Simple SSL Certificate Creator
# Creates self-signed certificates for development
# ==========================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CERT_DIR="./docker/nginx/dev-cert"

echo -e "${GREEN}Creating SSL certificates for development...${NC}\n"

# Create directory
mkdir -p "$CERT_DIR"

# Try mkcert first (best option)
if command -v mkcert &> /dev/null; then
    echo -e "${GREEN}Using mkcert (trusted certificates)${NC}"
    mkcert -install 2>/dev/null || true
    mkcert -cert-file "$CERT_DIR/cert.pem" \
           -key-file "$CERT_DIR/key.pem" \
           localhost 127.0.0.1 ::1

    echo -e "\n${GREEN}✓ Certificates created with mkcert${NC}"
    echo -e "${GREEN}✓ These will be trusted by your browser${NC}"

# Fallback to OpenSSL
else
    echo -e "${YELLOW}mkcert not found, using OpenSSL${NC}"

    # Create config file to avoid interactive prompts
    cat > "$CERT_DIR/openssl.cnf" << 'EOF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C=US
ST=Development
L=Local
O=Dev
CN=localhost

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

    # Generate certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/key.pem" \
        -out "$CERT_DIR/cert.pem" \
        -config "$CERT_DIR/openssl.cnf" 2>/dev/null

    # Cleanup
    rm -f "$CERT_DIR/openssl.cnf"

    echo -e "\n${GREEN}✓ Self-signed certificates created${NC}"
    echo -e "${YELLOW}⚠️  Your browser will show a security warning${NC}"
    echo -e "${YELLOW}   Click 'Advanced' and 'Proceed to localhost'${NC}"
fi

# Verify certificates were created
if [ -f "$CERT_DIR/cert.pem" ] && [ -f "$CERT_DIR/key.pem" ]; then
    echo -e "\n${GREEN}Certificate files:${NC}"
    echo -e "  • $CERT_DIR/cert.pem"
    echo -e "  • $CERT_DIR/key.pem"

    # Show expiry
    EXPIRY=$(openssl x509 -in "$CERT_DIR/cert.pem" -noout -enddate | cut -d= -f2)
    echo -e "\n${GREEN}Expires: ${NC}$EXPIRY"

    echo -e "\n${GREEN}✓ SSL certificates ready!${NC}"
else
    echo -e "\n${RED}✗ Failed to create certificates${NC}"
    echo -e "${YELLOW}Please check errors above or install mkcert:${NC}"
    echo -e "  brew install mkcert  # macOS"
    echo -e "  sudo apt install mkcert  # Ubuntu"
    exit 1
fi
