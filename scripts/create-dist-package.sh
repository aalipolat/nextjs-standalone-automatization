set -e  # Stops the script if an error occurs
set -o pipefail

# Define Color Codes
# Cyan for Info Messages
INFO_COLOR='\033[0;36m'
# Green for Success Messages
SUCCESS_COLOR='\033[0;32m'
# Red for Error/Cleanup Messages
ERROR_COLOR='\033[0;31m'
# Reset
NC='\033[0m'

# Function to start a task with a spinner
start_task() {
    TASK_NAME=$1
    echo -e "${INFO_COLOR}---> ${TASK_NAME}...${NC}"
    # Start the spinner in the background
    (
        i=0
        sp="/-\|"
        while true; do
            printf "\r${INFO_COLOR}   [${sp:i++%${#sp}:1}] ${TASK_NAME} in progress...${NC}"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

# Function to end a task (success or failure)
end_task() {
local STATUS=$1
    local MESSAGE=$2
    
    # Stop the background spinner process and ignore potential errors (e.g., if it's already finished)
    # Using '|| true' ensures set -e doesn't halt the script if kill fails
    ( kill $SPINNER_PID > /dev/null 2>&1 ) || true
    # Wait for the process to truly terminate, ignoring errors
    wait $SPINNER_PID 2>/dev/null || true
    
    # Clear the spinner line
    printf "\r%*s\r" $(tput cols) ""

    if [ "$STATUS" = "SUCCESS" ]; then
        echo -e "${SUCCESS_COLOR}  ✅ ${MESSAGE} completed successfully.${NC}"
    else
        echo -e "${ERROR_COLOR}  ❌ ${MESSAGE} failed.${NC}"
    fi
}

# Error trap mechanism
cleanup_on_error() {
    end_task "ERROR" "Process"
    echo -e "${ERROR_COLOR}🚨 An error occurred during the build process! Deleting 'dist/' folder...${NC}"
    rm -rf dist
    echo -e "${ERROR_COLOR}🧹 'dist/' folder cleaned up.${NC}"
    exit 1
}

# Execute cleanup_on_error function upon error (ERR)
trap 'cleanup_on_error' ERR

# ==========================================================
# 🚀 Starting Packaging For Distribute Script
# ==========================================================
echo -e "\n${INFO_COLOR}##########################################################${NC}"
echo -e "${INFO_COLOR}## 🚀 Starting Packaging Process                        ##${NC}"
echo -e "${INFO_COLOR}##########################################################${NC}"
echo -e "${INFO_COLOR}  ('dist/' will be automatically deleted upon error)${NC}"
echo -e "${INFO_COLOR}----------------------------------------------------------${NC}"

# 1. Clean old dist folder
start_task "Cleaning and creating new distribution (dist) artifact container"
rm -rf dist
rm -rf dist.zip
mkdir -p dist
end_task "SUCCESS" "Distribution artifact container (dist) preparation"

# 2. Copy standalone output to dist/
start_task "Copying standalone files"
cp -r .next/standalone/. dist/
end_task "SUCCESS" "Standalone files copied"

# 3. Copy static assets
start_task "Copying static assets"
mkdir -p dist/.next/static
cp -r .next/static/. dist/.next/static
end_task "SUCCESS" "Static assets copied"

# 4. Copy public folder
start_task "Copying public folder"
cp -r public dist/public
end_task "SUCCESS" "Public folder copied"

# 5. Create minimal dist/package.json
start_task "Creating and adjusting minimal 'dist/package.json' file"
cp package.json dist/package.json

node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('dist/package.json', 'utf8'));
pkg.scripts = {
  start: 'node server.js',
};
delete pkg.devDependencies;
fs.writeFileSync('dist/package.json', JSON.stringify(pkg, null, 2) + '\n');
"
end_task "SUCCESS" "Minimal 'dist/package.json' creation"

# 6. Final structure display
echo -e "\n${SUCCESS_COLOR}=====================================================${NC}"
echo -e "${SUCCESS_COLOR}🎉 BUILD COMPLETED SUCCESSFULLY!${NC}"
echo -e "${SUCCESS_COLOR}=====================================================${NC}"
ls -1AF dist | sed 's/\/$//'