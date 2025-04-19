- `/mnt` has the starter files
- `/app` is the `WORKDIR`
# Run the following in order:
```bash
cp /mnt/* .
npm init
npm install express
npm install --save-dev nodemon
npx nodemon ./app.mjs
```

## Other good things todo:
```bash
apt-get update && apt-get install -y net-tools
netstat -tulpn
```
- `-t`: TCP
- `-u`: UDP
- `-l`: listening
- `-p`: show process name/PID
- `-n`: don’t resolve names (faster)
