#!/bin/bash

# Pubspec Lockfile Version Check Script
# Version: 1.0
#------------------------------------------------------------------------------------------------------------
# Author: 
# Alfred Tång (@oelburk) - github.com/oelburk

# Description:
# Script to compare the versions of dependencies in pubspec.lock with the latest versions on pub.dev.
# The script will prompt the user to select the type of dependencies to filter 
# (transitive, direct main, direct dev, or all). The script will then fetch the latest version of each 
# dependency from pub.dev and compare it with the local version. The results will be written to a file named 
# dependencies_versions.txt in the current directory.

# Dependencies:
# - jq: Command-line JSON processor (https://stedolan.github.io/jq/)
# - curl: Command-line tool for transferring data with URLs (https://curl.se/)
# Install the dependencies using your package manager (e.g., apt, yum, brew)

#------------------------------------------------------------------------------------------------------------

# Default path for pubspec.lock file is the current directory
DEFAULT_PATH="."

# Output file for the comparison results
OUTPUT_FILE="dependencies_versions.txt"

# Verbose flag (default to off)
verbose=0

# ANSI escape codes for colored output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print debug messages if verbose mode is enabled
debug_print() {
  if [[ $verbose -eq 1 ]]; then
    echo "${BLUE}$1${NC}"
  fi
}

# Function to print debug messages if verbose mode is enabled
error_print() {
  echo -e "${RED}Error: $1${NC}"
}

warning_print() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

success_print() {
  echo -e "${GREEN}$1${NC}"
}

# Function to display help
show_help() {
  echo "Usage: ./filter_dependencies.sh [options] [path_to_pubspec.lock]"
  echo
  echo "Options:"
  echo "  -v, --verbose    Enable verbose mode to show debug information"
  echo "  -h, --help       Show this help message and exit"
  echo
  echo "If no path is provided, the script will search for pubspec.lock in the current directory."
}

# Check for command-line arguments
search_path="$DEFAULT_PATH"
for arg in "$@"; do
  case $arg in
    -v|--verbose)
      verbose=1
      shift # Remove --verbose or -v from processing
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      # Assume any non-option argument is the path to pubspec.lock
      search_path="$arg"
      shift
      ;;
  esac
done

# Define the full path to the pubspec.lock file
PUBSPEC_LOCK_FILE="$search_path/pubspec.lock"

# Check if the pubspec.lock file exists
if [[ ! -f "$PUBSPEC_LOCK_FILE" ]]; then
  error_print "pubspec.lock file not found at $PUBSPEC_LOCK_FILE!"
  exit 1
fi

# Prompt the user to select dependency type
echo "Select dependency type to filter:"
echo "1. Transitive"
echo "2. Direct main"
echo "3. Direct dev"
echo "4. All"
read -p "Enter your choice (1, 2, 3, or 4): " choice

# Determine the dependency type based on user input
if [[ "$choice" == "1" ]]; then
  dependency_type="transitive"
elif [[ "$choice" == "2" ]]; then
  dependency_type="\"direct main\""
elif [[ "$choice" == "3" ]]; then
  dependency_type="\"direct dev\""
elif [[ "$choice" == "4" ]]; then
  dependency_type="all"
else
  error_print "Invalid choice. Please run the script again and select 1, 2, 3, or 4."
  exit 1
fi

# Clear the output file before writing and add the header
> "$OUTPUT_FILE"

# Function to compare two semantic versions
compare_versions() {
  if [[ "$1" == "$2" ]]; then
    return 0
  fi
  local ver1=$(echo -e "$1\n$2" | sort -V | head -n1)
  if [[ "$ver1" == "$1" ]]; then
    return 1 # 1 indicates the first version is older
  else
    return 2 # 2 indicates the first version is newer
  fi
}

# Function to process dependencies based on the type
process_dependencies() {
  success_print "Processing dependencies of type: $1, please wait..."
  local dep_type=$1
  local header=$2
  printf "%-50s %-15s %-15s\n" "$header" "Local version" "Latest version" >> "$OUTPUT_FILE"
  echo "----------------------------------------------------------------------------------" >> "$OUTPUT_FILE"

  awk -v dep_type="$dep_type" '
    /^[[:space:]]{2}[a-zA-Z0-9_-]+:$/ {
      package_name = $1
      gsub(":", "", package_name) # Remove the trailing colon
    }

    # Match lines with the selected dependency type
    $0 ~ "dependency: " dep_type {
      is_selected_dependency = 1
    }

    # Match lines with versions only if the package matches the selected dependency type
    /^[[:space:]]{4}version:/ && is_selected_dependency {
      version = $2
      gsub("\"", "", version) # Remove quotes from the version string
      print package_name ": " version
      package_name = ""
      version = ""
      is_selected_dependency = 0
    }
  ' "$PUBSPEC_LOCK_FILE" | while read -r line; do
    # Split the output from awk into package name and version
    package_name=$(echo "$line" | awk '{print $1}' | tr -d ':')
    local_version=$(echo "$line" | awk '{print $2}')

    # Ensure the package name matches the expected pattern
    if [[ ! "$package_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      error_print "Invalid package name: $package_name"
      continue
    fi

    if [[ -z "$package_name" || -z "$local_version" ]]; then
      error_print "Skipping invalid line: $line"
      continue
    fi

    # Fetch the latest version from pub.dev
    response=$(curl -s "https://pub.dev/api/packages/$package_name")
    latest_version=$(echo "$response" | jq -r .latest.version)

    # Debugging output
    debug_print "Package: $package_name, Local version: $local_version"
    debug_print "Response from pub.dev: $response"
    debug_print "Parsed latest version: $latest_version"

    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
      warning_print "Failed to fetch the latest version for $package_name, skipping..."
    else
      compare_versions "$local_version" "$latest_version"
      version_comparison_result=$?
      if [[ $version_comparison_result -eq 1 ]]; then
        printf "%-50s %-15s %-15s\n" "$package_name" "$local_version" "$latest_version" >> "$OUTPUT_FILE"
      fi
    fi
  done
  echo ""
}

# Process dependencies based on user selection
if [[ "$dependency_type" == "all" ]]; then
  process_dependencies "\"direct main\"" "Direct Main Dependencies"
   echo "" >> "$OUTPUT_FILE"
  process_dependencies "\"direct dev\"" "Direct Dev Dependencies"
   echo "" >> "$OUTPUT_FILE"
  process_dependencies "transitive" "Transitive Dependencies"
else
  process_dependencies "$dependency_type" "$dependency_type Dependencies"
fi

echo ""
success_print "Filtered dependency versions have been written to $OUTPUT_FILE"