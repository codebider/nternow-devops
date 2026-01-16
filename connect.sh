#!/bin/bash

# DevOps Tool for AWS EC2 and Database Connections
# Usage: ./connect.sh [staging-ec2|staging-db|prod-ec2|prod-db]

set -e

# Configuration
STAGING_EC2_INSTANCE="i-0d4f1bf4174b68bf1"
PROD_EC2_INSTANCE="i-0283bb15f09c118af"
REGION="us-east-1"

STAGING_DB_HOST="nternow-staging-db.cuwf5kwmrqa1.us-east-1.rds.amazonaws.com"
PROD_DB_HOST="nternow-prod-db-2.cuwf5kwmrqa1.us-east-1.rds.amazonaws.com"

STAGING_DB_LOCAL_PORT="3307"
PROD_DB_LOCAL_PORT="3308"
DB_REMOTE_PORT="3306"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI is not installed.${NC}"
        echo "Please install it from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
}

# Function to check if Session Manager Plugin is installed
check_session_manager() {
    if ! command -v session-manager-plugin &> /dev/null; then
        echo -e "${RED}Error: Session Manager Plugin is not installed.${NC}"
        echo "Please install it from: https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html"
        exit 1
    fi
}

# Function to check if expect is installed
check_expect() {
    if ! command -v expect &> /dev/null; then
        echo -e "${YELLOW}Warning: 'expect' is not installed. Auto-switching to ubuntu user will not work.${NC}"
        echo "Install expect with: brew install expect"
        echo "Or manually type 'sudo su - ubuntu' after connecting."
        return 1
    fi
    return 0
}

# Function to connect to staging EC2
connect_staging_ec2() {
    echo -e "${GREEN}Connecting to Staging EC2 instance...${NC}"
    echo -e "${BLUE}Instance ID: ${STAGING_EC2_INSTANCE}${NC}"
    
    if check_expect; then
        echo -e "${YELLOW}Automatically switching to ubuntu user...${NC}"
        expect -c "
set timeout 30
spawn aws ssm start-session --target $STAGING_EC2_INSTANCE --region $REGION
expect {
    timeout {
        send \"sudo su - ubuntu\r\"
        interact
    }
    eof {
        exit
    }
    -re \".+\" {
        send \"sudo su - ubuntu\r\"
        interact
    }
}
"
    else
        aws ssm start-session --target "$STAGING_EC2_INSTANCE" --region "$REGION"
    fi
}

# Function to connect to prod EC2
connect_prod_ec2() {
    echo -e "${GREEN}Connecting to Production EC2 instance...${NC}"
    echo -e "${BLUE}Instance ID: ${PROD_EC2_INSTANCE}${NC}"
    
    if check_expect; then
        echo -e "${YELLOW}Automatically switching to ubuntu user...${NC}"
        expect -c "
set timeout 30
spawn aws ssm start-session --target $PROD_EC2_INSTANCE --region $REGION
expect {
    timeout {
        send \"sudo su - ubuntu\r\"
        interact
    }
    eof {
        exit
    }
    -re \".+\" {
        send \"sudo su - ubuntu\r\"
        interact
    }
}
"
    else
        aws ssm start-session --target "$PROD_EC2_INSTANCE" --region "$REGION"
    fi
}

# Function to connect to staging DB
connect_staging_db() {
    echo -e "${GREEN}Setting up port forwarding to Staging Database...${NC}"
    echo -e "${BLUE}Local port: ${STAGING_DB_LOCAL_PORT}${NC}"
    echo -e "${BLUE}Remote host: ${STAGING_DB_HOST}${NC}"
    echo -e "${YELLOW}Database will be available at: 127.0.0.1:${STAGING_DB_LOCAL_PORT}${NC}"
    echo -e "${YELLOW}Keep this terminal window open to maintain the connection.${NC}"
    echo ""
    
    aws ssm start-session \
        --target "$STAGING_EC2_INSTANCE" \
        --region "$REGION" \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters "{\"portNumber\":[\"${DB_REMOTE_PORT}\"], \"localPortNumber\":[\"${STAGING_DB_LOCAL_PORT}\"], \"host\":[\"${STAGING_DB_HOST}\"]}"
}

# Function to connect to prod DB
connect_prod_db() {
    echo -e "${GREEN}Setting up port forwarding to Production Database...${NC}"
    echo -e "${BLUE}Local port: ${PROD_DB_LOCAL_PORT}${NC}"
    echo -e "${BLUE}Remote host: ${PROD_DB_HOST}${NC}"
    echo -e "${YELLOW}Database will be available at: 127.0.0.1:${PROD_DB_LOCAL_PORT}${NC}"
    echo -e "${YELLOW}Keep this terminal window open to maintain the connection.${NC}"
    echo ""
    
    aws ssm start-session \
        --target "$PROD_EC2_INSTANCE" \
        --region "$REGION" \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters "{\"portNumber\":[\"${DB_REMOTE_PORT}\"], \"localPortNumber\":[\"${PROD_DB_LOCAL_PORT}\"], \"host\":[\"${PROD_DB_HOST}\"]}"
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}DevOps Connection Tool${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  staging-ec2    Connect to Staging EC2 instance"
    echo "  staging-db    Connect to Staging Database (port forwarding to 127.0.0.1:3307)"
    echo "  prod-ec2     Connect to Production EC2 instance"
    echo "  prod-db       Connect to Production Database (port forwarding to 127.0.0.1:3308)"
    echo ""
    echo "Examples:"
    echo "  $0 staging-ec2"
    echo "  $0 staging-db"
    echo "  $0 prod-ec2"
    echo "  $0 prod-db"
}

# Main script
main() {
    # Check prerequisites
    check_aws_cli
    check_session_manager
    
    # Parse command
    case "${1:-}" in
        staging-ec2)
            connect_staging_ec2
            ;;
        staging-db)
            connect_staging_db
            ;;
        prod-ec2)
            connect_prod_ec2
            ;;
        prod-db)
            connect_prod_db
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
