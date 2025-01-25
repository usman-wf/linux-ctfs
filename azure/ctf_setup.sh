#!/bin/bash

# System setup
sudo apt update
sudo apt install -y netcat nmap tree

# SSH configuration
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Create challenge directory
sudo -u ctf_user mkdir -p /home/ctf_user/ctf_challenges
cd /home/ctf_user/ctf_challenges

# Create verify script
cat > /usr/local/bin/verify << 'EOFVERIFY'
#!/bin/bash

ANSWERS=(
    "CTF{finding_hidden_treasures}"
    "CTF{search_and_discover}"
    "CTF{size_matters_in_linux}"
    "CTF{user_enumeration_expert}"
    "CTF{permission_sleuth}"
    "CTF{network_detective}"
    "CTF{decoding_master}"
    "CTF{ssh_security_master}"
)

check_flag() {
    challenge_num=$1
    submitted_flag=$2
    
    if [ "$submitted_flag" = "CTF{example}" ]; then
        echo "✓ Example flag verified! Now try finding real flags."
        show_progress
        return 0
    fi
    
    if [ "$submitted_flag" = "${ANSWERS[$((challenge_num-1))]}" ]; then
        echo "✓ Correct flag for Challenge $challenge_num!"
        echo "$challenge_num" >> ~/.completed_challenges
        sort -u ~/.completed_challenges > ~/.completed_challenges.tmp
        mv ~/.completed_challenges.tmp ~/.completed_challenges
    else
        echo "✗ Incorrect flag for Challenge $challenge_num. Try again!"
    fi
    show_progress
}

show_progress() {
    local completed=0
    if [ -f ~/.completed_challenges ]; then
        completed=$(sort -u ~/.completed_challenges | wc -l)
    fi
    
    echo "Flags Found: $completed/8"
    
    if [ "$completed" -eq 8 ]; then
        echo "Congratulations! You've completed all challenges!"
    fi
}

case "$1" in
    "progress")
        show_progress
        ;;
    [1-8])
        if [ -z "$2" ]; then
            echo "Usage: verify [challenge_number] [flag]"
            exit 1
        fi
        check_flag "$1" "$2"
        ;;
    *)
        echo "Usage:"
        echo "  verify [challenge_number] [flag] - Check a flag"
        echo "  verify progress - Show progress"
        echo
        echo "Example: verify 1 CTF{example}"
        ;;
esac
EOFVERIFY

sudo chmod +x /usr/local/bin/verify

# Create setup check script
cat > /usr/local/bin/check_setup << 'EOF'
#!/bin/bash
if [ ! -f /var/log/setup_complete ]; then
    echo "System is still being configured. Please wait..."
    exit 1
fi
EOF

chmod +x /usr/local/bin/check_setup

# Add to bash profile
echo "/usr/local/bin/check_setup" >> /home/ctf_user/.profile

# Create MOTD
cat > /etc/motd << 'EOFMOTD'
+==============================================+
|  Learn To Cloud - Linux Command Line CTF    |
+==============================================+

8 Progressive Linux Challenges

Commands:
  verify progress     - Show progress
  verify [num] [flag] - Submit flag
  verify 1 CTF{example} - Test system

First: Complete learntocloud.guide/phase1
+==============================================+
EOFMOTD

# Beginner Challenges
# Challenge 1: Simple hidden file
echo "CTF{finding_hidden_treasures}" > /home/ctf_user/ctf_challenges/.hidden_flag

# Challenge 2: Basic file search
mkdir -p /home/ctf_user/documents/projects/backup
echo "CTF{search_and_discover}" > /home/ctf_user/documents/projects/backup/secret_notes.txt

# Intermediate Challenges
# Challenge 3: Log analysis
sudo dd if=/dev/urandom of=/var/log/large_log_file.log bs=1M count=500
echo "CTF{size_matters_in_linux}" | sudo tee -a /var/log/large_log_file.log
sudo chown ctf_user:ctf_user /var/log/large_log_file.log

# Challenge 4: User investigation
sudo useradd -u 1002 -m flag_user
echo "CTF{user_enumeration_expert}" | sudo tee /home/flag_user/.profile
sudo chown flag_user:flag_user /home/flag_user/.profile

# Challenge 5: Permission analysis
sudo mkdir -p /opt/systems/config
echo "CTF{permission_sleuth}" | sudo tee /opt/systems/config/system.conf
sudo chmod 777 /opt/systems/config/system.conf

# Advanced Challenges
# Challenge 6: Service discovery
cat > /usr/local/bin/secret_service.sh << 'EOF'
#!/bin/bash
while true; do
    echo -e "HTTP/1.1 200 OK\n\nCTF{network_detective}" | nc -l -p 8080
done
EOF
sudo chmod +x /usr/local/bin/secret_service.sh
sudo nohup /usr/local/bin/secret_service.sh &

# Challenge 7: Encoding challenge
echo "CTF{decoding_master}" | base64 | base64 > /home/ctf_user/ctf_challenges/encoded_flag.txt

# Challenge 8: Advanced SSH setup
sudo mkdir -p /home/ctf_user/.ssh/secrets/backup
echo "CTF{ssh_security_master}" | sudo tee /home/ctf_user/.ssh/secrets/backup/.authorized_keys
sudo chown -R ctf_user:ctf_user /home/ctf_user/.ssh
sudo chmod 700 /home/ctf_user/.ssh
sudo chmod 600 /home/ctf_user/.ssh/secrets/backup/.authorized_keys

# Set permissions
sudo chown -R ctf_user:ctf_user /home/ctf_user/ctf_challenges

# Enable MOTD display in PAM
sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/login
sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/sshd
sudo systemctl restart ssh

# Mark setup as complete
touch /var/log/setup_complete

echo "CTF environment setup complete!"