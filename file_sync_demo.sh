#!/bin/bash
# Multi-Site NFS File Sync Test Script
# Tests NFS synchronization across HQ, Branch, and Remote sites

echo "Multi-Site NFS File Sync Test"
echo "============================="
echo

# Global variables
CURRENT_SITE=""
SHARED_PATH=""
IP_ADDRESS=""

# Detect and verify NFS setup
detect_nfs_setup() {
    IP_ADDRESS=$(echo $SSH_CONNECTION | awk '{print $3}')
    
    echo "Detecting NFS configuration..."
    echo "Current IP: $IP_ADDRESS"
    echo "Hostname: $(hostname)"
    echo
    
    case $IP_ADDRESS in
        192.168.10.*)
            CURRENT_SITE="HQ"
            if [[ -d "/shared" ]]; then
                SHARED_PATH="/shared"
                echo "HQ Server detected - Using /shared"
            else
                echo "ERROR: HQ Server but /shared directory not found"
                return 1
            fi
            ;;
        192.168.20.*)
            CURRENT_SITE="BRANCH"
            if mount | grep -q "192.168.10.10:/shared"; then
                SHARED_PATH="/mnt/shared"
                echo "Branch Office detected - NFS mounted at /mnt/shared"
            else
                echo "ERROR: Branch Office but NFS not mounted"
                echo "Run: sudo mount -t nfs 192.168.10.10:/shared /mnt/shared"
                return 1
            fi
            ;;
        192.168.30.*)
            CURRENT_SITE="REMOTE"
            if mount | grep -q "192.168.10.10:/shared"; then
                SHARED_PATH="/mnt/shared"
                echo "Remote Office detected - NFS mounted at /mnt/shared"
            else
                echo "ERROR: Remote Office but NFS not mounted"
                echo "Run: sudo mount -t nfs 192.168.10.10:/shared /mnt/shared"
                return 1
            fi
            ;;
        *)
            echo "ERROR: Not running on configured NFS infrastructure"
            echo "This test requires running on HQ (192.168.10.10), Branch (192.168.20.10), or Remote (192.168.30.10)"
            return 1
            ;;
    esac
    
    # Create directory structure if needed
    echo "Checking directory structure..."
    for dir in common hq branch remote temp custom; do
        if [[ -d "$SHARED_PATH/$dir" ]]; then
            echo "  $SHARED_PATH/$dir - OK"
        else
            echo "  $SHARED_PATH/$dir - Creating..."
            mkdir -p "$SHARED_PATH/$dir" 2>/dev/null || echo "  Failed to create directory"
        fi
    done
    
    # Test write access
    echo "Testing write access..."
    test_file="$SHARED_PATH/common/write-test-$(date +%s).tmp"
    if echo "Write test from $CURRENT_SITE" > "$test_file" 2>/dev/null; then
        echo "  Write access - OK"
        rm -f "$test_file"
    else
        echo "  ERROR: No write access to shared directory"
        return 1
    fi
    
    echo
    echo "NFS configuration verified successfully"
    echo "Site: $CURRENT_SITE"
    echo "Shared Path: $SHARED_PATH"
    echo
    return 0
}

# Create multi-site test file
create_test_file() {
    echo "Creating multi-site test file..."
    
    TEST_FILE="$SHARED_PATH/common/multi-site-test.txt"
    
    cat > "$TEST_FILE" << EOF
Multi-Site Synchronization Test
==============================
File ID: MST-$(date +%s)
Created by: $CURRENT_SITE
Created at: $(date)
IP Address: $IP_ADDRESS

This file demonstrates synchronization across NFS infrastructure.

Instructions for verification:
1. SSH to another site (HQ/Branch/Remote)
2. Check this file exists: $TEST_FILE
3. Modify this file from another site
4. Come back here and see the changes

Modification Log:
[$(date)] File created by $CURRENT_SITE
EOF
    
    if [[ -f "$TEST_FILE" ]]; then
        echo "Test file created successfully"
        echo "Location: $TEST_FILE"
        echo "Size: $(wc -c < "$TEST_FILE") bytes"
        echo "File is now available on all sites"
    else
        echo "ERROR: Failed to create test file"
        return 1
    fi
}

# Create custom file
create_custom_file() {
    echo "Create Custom File"
    echo "=================="
    echo
    
    # Get filename
    while true; do
        echo -n "Enter filename: "
        read filename
        
        if [[ -z "$filename" ]]; then
            echo "Filename cannot be empty"
            continue
        fi
        
        filename=$(basename "$filename")
        
        if [[ "$filename" != *.* ]]; then
            filename="${filename}.txt"
        fi
        
        break
    done
    
    # Choose directory
    echo
    echo "Select directory:"
    echo "1) common/ (accessible by all sites)"
    echo "2) custom/ (for custom files)"
    echo "3) ${CURRENT_SITE,,}/ (site-specific)"
    echo -n "Choose (1-3): "
    read dir_choice
    
    case $dir_choice in
        1) target_dir="common" ;;
        2) target_dir="custom" ;;
        3) target_dir="${CURRENT_SITE,,}" ;;
        *) target_dir="custom" ;;
    esac
    
    CUSTOM_FILE="$SHARED_PATH/$target_dir/$filename"
    
    # Check if file exists
    if [[ -f "$CUSTOM_FILE" ]]; then
        echo "File already exists: $CUSTOM_FILE"
        echo -n "Overwrite? (y/N): "
        read overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo "Operation cancelled"
            return 1
        fi
    fi
    
    # Choose input method
    echo
    echo "Choose input method:"
    echo "1) Interactive (multi-line)"
    echo "2) Single line"
    echo "3) Template only"
    echo -n "Choose (1-3): "
    read content_choice
    
    case $content_choice in
        1)
            echo
            echo "Enter content (type 'EOF' to finish):"
            
            cat > "$CUSTOM_FILE" << EOF
Custom File: $filename
Created by: $CURRENT_SITE
Created at: $(date)
Location: $target_dir/

Content:
========
EOF
            
            while true; do
                read line
                if [[ "$line" == "EOF" ]]; then
                    break
                fi
                echo "$line" >> "$CUSTOM_FILE"
            done
            ;;
            
        2)
            echo -n "Enter content: "
            read content
            
            cat > "$CUSTOM_FILE" << EOF
Custom File: $filename
Created by: $CURRENT_SITE
Created at: $(date)
Location: $target_dir/

Content: $content
EOF
            ;;
            
        3)
            cat > "$CUSTOM_FILE" << EOF
Custom File: $filename
Created by: $CURRENT_SITE
Created at: $(date)
Location: $target_dir/

This is a custom file created from $CURRENT_SITE.
You can edit this file from any site and changes will sync automatically.

File paths:
- HQ:     /shared/$target_dir/$filename
- Branch: /mnt/shared/$target_dir/$filename  
- Remote: /mnt/shared/$target_dir/$filename

To edit: nano $CUSTOM_FILE

Modification Log:
[$(date)] File created by $CURRENT_SITE
EOF
            ;;
    esac
    
    if [[ -f "$CUSTOM_FILE" ]]; then
        echo
        echo "Custom file created successfully"
        echo "Location: $CUSTOM_FILE"
        echo "Size: $(wc -c < "$CUSTOM_FILE") bytes"
        echo "Lines: $(wc -l < "$CUSTOM_FILE")"
        echo
        echo "File is now synchronized across all sites"
    else
        echo "ERROR: Failed to create custom file"
        return 1
    fi
}

# Add modification to test file
add_modification() {
    echo "Adding modification from $CURRENT_SITE..."
    
    TEST_FILE="$SHARED_PATH/common/multi-site-test.txt"
    
    if [[ -f "$TEST_FILE" ]]; then
        echo "[$(date)] Modified by $CURRENT_SITE - Entry #$(($RANDOM % 1000))" >> "$TEST_FILE"
        echo "Modification added"
        echo
        echo "Last 5 lines:"
        tail -5 "$TEST_FILE"
        echo
    else
        echo "ERROR: Test file not found. Create it first."
    fi
}

# Show file status
show_file_status() {
    echo "File Status"
    echo "==========="
    
    TEST_FILE="$SHARED_PATH/common/multi-site-test.txt"
    
    if [[ -f "$TEST_FILE" ]]; then
        echo "Test file exists and is accessible"
        echo
        echo "File Information:"
        echo "  Size: $(wc -c < "$TEST_FILE") bytes"
        echo "  Lines: $(wc -l < "$TEST_FILE")"
        echo "  Modified: $(stat -c %y "$TEST_FILE" 2>/dev/null || date -r "$TEST_FILE")"
        echo
        echo "File content:"
        echo "============="
        cat "$TEST_FILE"
        echo "============="
    else
        echo "Test file not found"
        echo "Create the test file first (option 2)"
    fi
}

# Create collaboration document
create_collaboration_doc() {
    echo "Creating collaboration document..."
    
    COLLAB_FILE="$SHARED_PATH/common/collaboration-$(date +%s).txt"
    
    cat > "$COLLAB_FILE" << EOF
Collaboration Document
=====================
Started by: $CURRENT_SITE at $(date)

Project: Multi-Site Infrastructure Demo
Status: In Progress

Team Updates:
[$CURRENT_SITE - $(date +%H:%M:%S)] Collaboration document created
[$CURRENT_SITE - $(date +%H:%M:%S)] Demonstrating real-time file sharing
[$CURRENT_SITE - $(date +%H:%M:%S)] All sites can now see and edit this document

Next Steps:
1. Other team members can SSH to their sites
2. Edit this file: $COLLAB_FILE
3. Add their updates and see instant synchronization

To add update from another site:
echo "[\$(hostname) - \$(date +%H:%M:%S)] Your update here" >> $COLLAB_FILE
EOF
    
    echo "Collaboration document created"
    echo "Location: $COLLAB_FILE"
    echo
    echo "Document content:"
    cat "$COLLAB_FILE"
    echo
}

# Verify NFS functionality
verify_nfs() {
    echo "Verifying NFS functionality..."
    
    VERIFY_FILE="$SHARED_PATH/common/nfs-verify-$(date +%s).txt"
    
    cat > "$VERIFY_FILE" << EOF
NFS Verification Test
Created by: $CURRENT_SITE
Timestamp: $(date)
Random ID: $(date +%s)-$(($RANDOM % 10000))
EOF
    
    if [[ -f "$VERIFY_FILE" ]]; then
        echo "Verification file created successfully"
        
        local_size=$(wc -c < "$VERIFY_FILE")
        local_checksum=$(md5sum "$VERIFY_FILE" 2>/dev/null | awk '{print $1}' || echo "N/A")
        
        echo "File details:"
        echo "  Size: $local_size bytes"
        echo "  MD5: $local_checksum"
        echo "  Location: $VERIFY_FILE"
        echo
        
        echo "This file should be visible from other sites:"
        case $CURRENT_SITE in
            "HQ")
                echo "  Branch: ssh admin2@192.168.20.10 'cat $VERIFY_FILE'"
                echo "  Remote: ssh admin3@192.168.30.10 'cat $VERIFY_FILE'"
                ;;
            "BRANCH")
                echo "  HQ: ssh admin1@192.168.10.10 'cat ${VERIFY_FILE/\/mnt\/shared/\/shared}'"
                echo "  Remote: ssh admin3@192.168.30.10 'cat $VERIFY_FILE'"
                ;;
            "REMOTE")
                echo "  HQ: ssh admin1@192.168.10.10 'cat ${VERIFY_FILE/\/mnt\/shared/\/shared}'"
                echo "  Branch: ssh admin2@192.168.20.10 'cat $VERIFY_FILE'"
                ;;
        esac
        
        echo "File will be automatically removed in 30 seconds"
        (sleep 30 && rm -f "$VERIFY_FILE" 2>/dev/null) &
        
    else
        echo "ERROR: Failed to create verification file"
        return 1
    fi
}

# Show all test files
show_all_files() {
    echo "All Test Files"
    echo "=============="
    
    echo "Files in common directory:"
    if [[ -d "$SHARED_PATH/common" ]]; then
        ls -la "$SHARED_PATH/common"/*.txt 2>/dev/null || echo "  No .txt files found"
    else
        echo "  Directory not accessible"
    fi
    
    echo
    echo "Files in custom directory:"
    if [[ -d "$SHARED_PATH/custom" ]]; then
        ls -la "$SHARED_PATH/custom"/* 2>/dev/null || echo "  No files found"
    else
        echo "  Directory not accessible"
    fi
    
    echo
    echo "Files in site-specific directory (${CURRENT_SITE,,}):"
    if [[ -d "$SHARED_PATH/${CURRENT_SITE,,}" ]]; then
        ls -la "$SHARED_PATH/${CURRENT_SITE,,}"/* 2>/dev/null || echo "  No files found"
    else
        echo "  Directory not accessible"
    fi
}

# Cleanup test files
cleanup_files() {
    echo "Cleaning up test files..."
    
    patterns=("multi-site-test.txt" "collaboration-*.txt" "nfs-verify-*.txt" "*-test-*.txt")
    
    for pattern in "${patterns[@]}"; do
        find "$SHARED_PATH/common" -name "$pattern" 2>/dev/null | while read file; do
            if rm -f "$file" 2>/dev/null; then
                echo "Removed $(basename "$file")"
            else
                echo "Failed to remove $(basename "$file")"
            fi
        done
    done
    
    # Handle custom files
    if [[ -d "$SHARED_PATH/custom" ]] && [[ $(ls -1 "$SHARED_PATH/custom"/* 2>/dev/null | wc -l) -gt 0 ]]; then
        echo
        echo "Custom files found:"
        ls "$SHARED_PATH/custom"/*
        echo
        echo -n "Remove custom files too? (y/N): "
        read remove_custom
        if [[ "$remove_custom" == "y" || "$remove_custom" == "Y" ]]; then
            rm -f "$SHARED_PATH/custom"/* 2>/dev/null
            echo "Custom files removed"
        fi
    fi
    
    echo "Cleanup completed"
}

# Main menu
show_menu() {
    echo "Multi-Site NFS Test Menu"
    echo "========================"
    echo "1) Verify NFS configuration"
    echo "2) Create multi-site test file"
    echo "3) Add modification from $CURRENT_SITE"
    echo "4) Show file status"
    echo "5) Create collaboration document"
    echo "6) Verify NFS functionality"
    echo "7) Show all test files"
    echo "8) Clean up test files"
    echo "9) Create custom file"
    echo "10) Exit"
    echo
    echo -n "Select option (1-10): "
}

# Main execution
main() {
    echo "Initializing NFS test..."
    
    if detect_nfs_setup; then
        echo "Ready to test multi-site synchronization"
        echo
        
        while true; do
            show_menu
            read choice
            echo
            
            case $choice in
                1) detect_nfs_setup ;;
                2) create_test_file ;;
                3) add_modification ;;
                4) show_file_status ;;
                5) create_collaboration_doc ;;
                6) verify_nfs ;;
                7) show_all_files ;;
                8) cleanup_files ;;
                9) create_custom_file ;;
                10) echo "Exiting..."; exit 0 ;;
                *) echo "Invalid option. Please select 1-10." ;;
            esac
            
            echo
            echo "Press Enter to continue..."
            read
            clear
            echo "Multi-Site NFS Test - Current Site: $CURRENT_SITE"
            echo
        done
    else
        echo
        echo "NFS configuration issues detected"
        echo "Requirements:"
        echo "- Run on HQ (192.168.10.10), Branch (192.168.20.10), or Remote (192.168.30.10)"
        echo "- NFS server running on HQ"
        echo "- NFS mounted on Branch and Remote"
        echo "- Write permissions to shared directories"
        echo
        echo "To mount NFS on Branch/Remote:"
        echo "sudo mount -t nfs 192.168.10.10:/shared /mnt/shared"
        exit 1
    fi
}

# Run main function
main