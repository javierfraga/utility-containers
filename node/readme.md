- `/files` has the starter files
- `/mnt` is the `WORKDIR`
# Run the following in order:
```bash
cp /files/* .
npm init
npm install express
npm install --save-dev nodemon
npx nodemon ./app.mjs
```

## Other good things todo:
```bash
apt-get update
apt-get install -y iproute2
ss -tulpn
```
- `-t`: TCP
- `-u`: UDP
- `-l`: listening
- `-p`: show process name/PID
- `-n`: don’t resolve names (faster)

| Feature                  | `netstat` Option | `ss` Equivalent     |
| ------------------------ | ---------------- | ------------------- |
| Show listening ports     | netstat -tulpn   | ss -tulpn           |
| Show all TCP connections | netstat -ant     | ss -ant             |
| Show all UDP connections | netstat -anu     | ss -anu             |
| Show PID/program name    | netstat -p       | ss -p               |
| Show all interfaces      | netstat -i       | ip link show        |
| Show routing table       | netstat -r       | ip route show       |
| Show multicast           | netstat -g       | ip maddr show       |
| Show interface stats     | netstat -i       | ss -i or ip -s link |
