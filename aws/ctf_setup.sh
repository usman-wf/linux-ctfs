#!/bin/bash


sudo apt-get update

# Create a new user for CTF
sudo useradd -m -s /bin/bash ctf_user
sudo echo 'ctf_user:CTFpassword123!' | sudo chpasswd

# Enable password authentication
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
sudo systemctl restart ssh

sudo usermod -aG sudo ctf_user

# Create a directory for the CTF challenges
mkdir -p /home/ctf_user/ctf_challenges
cd /home/ctf_user/ctf_challenges

# Create a welcome file with instructions
cat << EOT > welcome.txt
Welcome to the Linux Command Line CTF Challenge!

Your goal is to find and collect all the flags hidden in this system.
Each flag is in the format CTF{some_text_here}.

Here are your challenges:

1. Find the hidden file in this directory and read its contents.
2. Locate the file with the word "secret" in its name anywhere in the /home/ctf_user directory.
3. Find the largest file in the /var/log directory and retrieve the flag from it.
4. Identify the user with UID 1002 and find the flag in their home directory.
5. Locate the file owned by root with permissions 777 and read its contents.
6. Find the process running on port 8080 and retrieve the flag from its command.
7. Decode the base64 encoded flag in the 'encoded_flag.txt' file.

Good luck, and happy hunting!
EOT

# Challenge 1: Hidden file
echo "CTF{hidden_files_revealed}" > .hidden_flag

# Challenge 2: File with "secret" in the name
echo "CTF{grep_is_your_friend}" > /home/ctf_user/very_secret_file.txt

# Challenge 3: Largest file in /var/log
touch /var/log/large_log_file.log
chown ctf_user:ctf_user /var/log/large_log_file.log
fallocate -l 500M /var/log/large_log_file.log
echo "CTF{size_matters_in_linux}" >> /var/log/large_log_file.log

# Challenge 4: User with UID 1001
sudo useradd -u 1002 flag_user
mkdir /home/flag_user
bash -c 'echo "CTF{user_detective}" >> /home/flag_user/flag.txt'
chown root:root /home/flag_user/flag.txt

# Challenge 5: File owned by root with 777 permissions
echo "CTF{permission_granted}" | sudo tee /root/everyone_can_access_me
sudo chmod 777 /root/everyone_can_access_me

# Challenge 6: Process running on port 8080
sudo apt install nmap
echo '#!/bin/bash
while true; do
    echo -e "HTTP/1.1 200 OK\n\nCTF{port_explorer}" | nc -l -p 8080
done' > port_8080_service.sh
chmod +x port_8080_service.sh
nohup ./port_8080_service.sh &

# Challenge 7: Base64 encoded flag
echo "Q1RGe2Jhc2U2NF9kZWNvZGVyfQ==" > encoded_flag.txt

# Set appropriate permissions
chown -R ctf_user:ctf_user /home/ctf_user/ctf_challenges

# Add a hint to the motd
echo "Welcome to the L2C Linux Command Line CTF! Make sure to review the material on learntocloud.guide/phase1 first. Your first challenge awaits in /home/ctf_user/ctf_challenges/welcome.txt" | sudo tee -a /etc/motd

echo "CTF environment setup complete!"
