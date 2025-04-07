# Redbelly-Monitoring

I have a Mini Monitoring Telegram bot for the Redbelly Testnet network. Anyone who doesn't have monitoring can use it.  Let me know if there are any issues with the bot. Thank you.

**Step 1: Add the following code: If you have already completed Step 1 and Step 2, please skip this.**

```nano /etc/systemd/system/redbelly.service```
```--http --http.addr=0.0.0.0 --http.corsdomain=* --http.vhosts=* --http.port=8545 --http.api eth,txpool,net,web3,rbn```
Place it before the --testnet flag and save 

**Step 2: Restart the node:**

```sudo systemctl restart redbelly.service```
Check logs:
```tail -f /var/log/redbelly/rbn_logs/rbbc_logs.log```
Check status: 
```sudo systemctl status redbelly.service```


**Step 3: Mini Monitoring Strategy:**

https://t.me/redbelly_monitoring_bot
