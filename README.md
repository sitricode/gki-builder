# GKI Builder  

Build Android GKI using GitHub Action!

## 🚀 Prerequisites

Before running the workflow, you need to add some secrets in your repository. There are:  

1. **`GH_TOKEN`** – Your GitHub personal access token.
   - [How to create PAT?](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)  

2. **`TOKEN`** – Your Telegram bot token.
   - [How to get that?](https://www.siteguarding.com/en/how-to-get-telegram-bot-api-token)  

4. **`CHAT_ID`** – Your Telegram Chat ID.
   - [How to get that?](https://www.wikihow.com/Know-Chat-ID-on-Telegram-on-Android)  

### ❓ How to Add the Secrets  
- Follow this guide: [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)  

## ⚙️ Configuration  

Before running the workflow, you must modify the following files according to your requirements:  

- **`config.sh`**
- **`build.sh`** (if you are a pro)

Once configured, you can start building!  

## ✅ Compatibility  

| Kernel Version | Support |
|-------------|---------|
| **5.10**    | ✅ Yes  |
| **>5.10**   | ❓Not tested |