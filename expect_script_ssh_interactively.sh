#!/usr/bin/expect -f
 
set timeout 5

# if passcode using stoken
#set passcode [exec echo "123456" | stoken | cut -d: -f2]
set passcode "passcode"
set password "password"

spawn ssh -o ServerAliveInterval=120 ashamril@server_name 
expect "Enter PASSCODE:" { send "$passcode\r" }
expect "Password:" { send "$password\r" }
interact
