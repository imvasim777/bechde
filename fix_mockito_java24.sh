#!/usr/bin/env bash

# Script: fix_mockito_java24.sh
# Description: Upgrades Byte Buddy to 1.15.5 and sets JVM flags for Java 24 compatibility.
# Fixes: "Mockito cannot mock this class" errors on JDK 24.

set -euo pipefail

# --- Configuration ---
BB_VER="1.15.5"       # Newest Byte Buddy for Java 24 support
SUREFIRE_VER="3.2.5"
SERVICES=("listings-service" "auth-service" "users-service" "payments-service" "media-service" "chat-service")

echo "🔧 Patching POMs for Java 24 + Mockito/ByteBuddy compatibility..."

# --- Function 1: Add Dependency Overrides ---
add_bb_overrides() {
    local pom="$1"

    # Only add if not already present
    if ! grep -q "<artifactId>byte-buddy</artifactId>" "$pom"; then
        echo "   -> Adding Byte Buddy $BB_VER to $(basename $(dirname "$pom"))"

        # Use AWK to insert dependencies right after the opening <dependencies> tag
        awk -v bb_ver="$BB_VER" '
        { print }
        /<dependencies>/ && !done {
            print "        "
            print "        <dependency>"
            print "            <groupId>net.bytebuddy</groupId>"
            print "            <artifactId>byte-buddy</artifactId>"
            print "            <version>" bb_ver "</version>"
            print "            <scope>test</scope>"
            print "        </dependency>"
            print "        <dependency>"
            print "            <groupId>net.bytebuddy</groupId>"
            print "            <artifactId>byte-buddy-agent</artifactId>"
            print "            <version>" bb_ver "</version>"
            print "            <scope>test</scope>"
            print "        </dependency>"
            done=1
        }
        ' "$pom" > "$pom.tmp" && mv "$pom.tmp" "$pom"
    fi
}

# --- Function 2: Configure Surefire Plugin ---
ensure_surefire_argline() {
    local pom="$1"
    local flags="--add-opens java.base/java.lang=ALL-UNNAMED -Dnet.bytebuddy.experimental=true"

    if grep -q "<artifactId>maven-surefire-plugin</artifactId>" "$pom"; then
        # If plugin exists but flags are missing, inject them
        if ! grep -q "net.bytebuddy.experimental" "$pom"; then
            echo "   -> Injecting JVM flags into surefire configuration..."
            awk -v flags="$flags" '
            BEGIN { in_plugin=0; in_surefire=0; inserted=0 }
            /<plugin>/ { in_plugin=1 }
            /<artifactId>maven-surefire-plugin<\/artifactId>/ { in_surefire=1 }

            # If inside surefire config, verify configuration block exists or needs creation
            in_plugin && in_surefire && /<\/configuration>/ && !inserted {
                print "                    <argLine>" flags "</argLine>"
                inserted=1
            }
            # Fallback if configuration tag is missing (simplified logic: just print current line)
            { print }

            /<\/plugin>/ { in_plugin=0; in_surefire=0 }
            ' "$pom" > "$pom.tmp" && mv "$pom.tmp" "$pom"
        fi
    else
        # If plugin does not exist, add the whole block
        echo "   -> Adding maven-surefire-plugin with Java 24 flags..."
        awk -v ver="$SUREFIRE_VER" -v flags="$flags" '
        { print }
        /<plugins>/ && !done {
            print "            <plugin>"
            print "                <groupId>org.apache.maven.plugins</groupId>"
            print "                <artifactId>maven-surefire-plugin</artifactId>"
            print "                <version>" ver "</version>"
            print "                <configuration>"
            print "                    <argLine>" flags "</argLine>"
            print "                </configuration>"
            print "            </plugin>"
            done=1
        }
        ' "$pom" > "$pom.tmp" && mv "$pom.tmp" "$pom"
    fi
}

# --- Execution Loop ---
for s in "${SERVICES[@]}"; do
    POM="services/$s/pom.xml"
    if [ -f "$POM" ]; then
        add_bb_overrides "$POM"
        ensure_surefire_argline "$POM"
    fi
done

echo "🧪 Verifying fix by running Listings Service tests..."
(cd services/listings-service && ../../mvnw -B -DskipTests=false test)

echo "✅ Done. If tests pass above, you can now run 'bash run_all_local.sh'"
