# WSO2 API Manager Monetization Test Setup (with ELK)

> ⚠️ **For Testing & Demo Purposes Only**
>
> This configuration is intended strictly for **local testing, experimentation, and demonstration**. It is **NOT** secured, optimized, or configured for production environments.

Get a full WSO2 API Manager setup with a monetized API, ELK analytics, and Stripe billing integration running with a single command.

**Here's what you should see when it's up:**

* **API Manager with a monetized API:**
    ![API Manager](./repo-images/monetized-api.png)
* **ELK stack with pre-configured dashboards:**
    ![ELK](./repo-images/elk-kibana-dashboard.png)
* **Stripe dashboard reflecting API usage billing:**
    ![Stripe](./repo-images/dynamic-billing-usage.png)


## 🛠️ Before You Start: Prerequisites

1.  **Install Rancher Desktop or Colima:**
    * This setup was tested on Rancher Desktop (using the Moby container engine) and Colima. Others like Docker Desktop *might* work, but haven't been tested.
    * Ideal to allocate **4-6 cores** and **4-8 GB memory** - `Preferences > Virtual Machine` in Rancher Desktop or `colima start --cpu 4 --memory 8` for Colima.
    * If you are using Rancher Desktop and facing container startup issues, try *disabling Kubernetes* in Rancher Desktop settings (to avoid potential port conflicts). This setup uses Docker Compose, so Kubernetes is not required.

2.  **Install Docker Compose:** Make sure you have `docker compose` available in your terminal.

3.  **Get Stripe API Keys:**
    * Create a Stripe account at https://dashboard.stripe.com/ if you don't have one. You need a couple of keys to connect WSO2 API Manager to Stripe. It's not a big deal, I'll explain:
    - Create a Sandbox for testing, Stripe used to call this Test mode until recently.
    - Go to `Developers`, near the bottom left of the sidebar (or wherever they change it to next) and copy the `Secret key` under API Keys. It should start with `sk_test_...`. This is your **`BillingEnginePlatformKey`**, keep it handy. 
        ![BillingEnginePlatformKey](./repo-images/BillingEnginePlatformAccountKey.png)
    - Next, go to `Connected accounts` and create one, go for a Standard account type (I think Stripe will change the account types very soon).
    - Paste the URL you get into a browser and just enter random data, it's easy. At payouts, choose the Stripe test option (it was somewhere near the bottom I think).
    - Once you are done, if you go back to the `Connected accounts` page, you'll see an account listed. 
    - Go into that account and copy the `Account ID` (it starts with `acct_...`). This is your **`ConnectedAccountKey`**, keep this handy as well. 
        ![ConnectedAccountKey](./repo-images/Connected-account-key.png)
    - That's it!

       
> #### Quick Explainer: How API Manager Maps to Stripe
>
> * **You (Tenant Admin):** You run the API Manager platform. You use your main Stripe account's `Secret Key` (`BillingEnginePlatformKey`) to link APIM with Stripe globally. You define the monetization plans (e.g., $0.10/call, $10/month) your organization requires. 
> * **API Publishers (e.g., different departments or partners):** They onboard onto your platform with their details (the random data we input earlier). They  attach different monetization plans you created to their APIs, which  they link to their specific Stripe *Connected Account* (`ConnectedAccountKey`). This is where *their* earnings will go.
> * **API Consumers (App Developers):** When they subscribe to a monetized API, Stripe customer objects and subscriptions are created under the *API Publisher's* Connected Account. Usage data gets pushed, and Stripe handles invoicing the consumer on behalf of the publisher.


## ▶️ How to Run
```bash
git clone https://github.com/viggnah/wso2-apim-monetization-docker && cd wso2-apim-monetization-docker && chmod +x ./start.sh && ./start.sh
```
*(The script will prompt you to enter the `BillingEnginePlatformKey` and `ConnectedAccountKey` you got earlier.)*


**API Manager**
* *Publisher Portal:* https://localhost:9500/publisher/apis
* *Developer Portal:* https://localhost:9500/devportal
* *Admin Portal:* https://localhost:9500/admin/dashboard
* *Username:* `admin`
* *Password:* `admin`

**Kibana Dashboard**

* *URL:* http://localhost:5601/app/dashboards#/view/f954a940-6ed4-11ec-9007-b93f9eb88870
* *Username:* `elastic`
* *Password:* `changeme` 

---

**✅ Testing the Flow**

1.  **Make API Calls:**
    * Go to the Developer Portal (https://localhost:9500/devportal) and log in (`admin`/`admin`).
    * Navigate to the `PizzaShackAPI`.
    * Go to the `Try Out` tab.
    * Use the pre-subscribed `SampleMonetizationApp` (it should be selected by default).
    * Generate a test key/token if needed.
    * Make a few API calls using the console.
2.  **Check Kibana:**
    * Open the Kibana Dashboard link (http://localhost:5601/app/dashboards#/view/f954a940-6ed4-11ec-9007-b93f9eb88870).
    * You should see the API calls reflected in the dashboards pretty instantly (otherwise hit the refresh button top right).
3.  **Push Billing Data to Stripe:**
    * Go back to your terminal (in the `wso2-apim-monetization-docker` directory).
    * Run the publishing script:
        ```bash
        ./apim/publish-monetization-data.sh
        ```
4.  **Verify in Stripe:**
    * Go to your Stripe dashboard.
    * Navigate to the `Connected account` you created earlier.
    * Check the `Subscriptions` section. You should see usage data and corresponding pending invoice items based on the calls you made and the $1.10/call plan.


## 🤔 What This Setup Does
1. Spins up an all-in-one API Manager and an ELK (Elasticsearch, Logstash, Kibana) setup. Note that we are using fluentd to forward the logs to Logstash, I just couldn't get filebeat working. 
2. Puts a simple sample API onto the API Manager (PizzaShackAPI)
3. Creates a sample monetization plan ($1.10 per API call or something) and attaches it to the API
4. Creates an app on the devportal (SampleMonetizationApp) and subscribes to this monetized API
5. Simulates a bit of traffic by making a few sample calls
6. Runs the billing data publishing task once at the end of the startup script to sync the initial usage with Stripe (eg: 5 calls at $1.10 per call - $5.50 is due)


## ⏹️ How to Stop 
* Go to your terminal and run 
```bash
~/.../wso2-apim-monetization-docker git:(main) ✗  ./stop.sh
```
*(This will stop and remove the Docker containers.)*


## 🔍 Troubleshooting Tips

* **Stuck on First Run?** Sometimes things hang, especially on the first go. Try stopping (`Ctrl+C`) and running `./start.sh` again.
* **Rancher High CPU?** Check Activity Monitor (Mac) or Task Manager (Windows) for `qemu` processes using high CPU. This can happen sometimes with Rancher Desktop (see [this potential issue](https://github.com/rancher-sandbox/rancher-desktop/issues/7087)). If CPU is maxed out, restarting Rancher Desktop usually helps.
* **Stripe Publishing Failed During Startup?** If the initial data push didn't work, you can run it manually anytime:
    ```bash
    ./apim/publish-monetization-data.sh
    ```
* **Check All Logs:**
    ```bash
    docker compose logs -f
    ```
* **Check Logs for a Specific Service:** (Replace `wso2-apim` with the service name from `docker-compose.yml`, e.g., `mysql`, `logstash`, `fluentd-agent`)
    ```bash
    docker compose logs wso2-apim
    docker compose logs -f wso2-apim # Follow logs
    ```
* **SSH into a Container:** (To poke around inside)
    ```bash
    docker exec -it wso2-apim bash # Replace wso2-apim if needed
    ```
* **More Commands:** Check out the [useful-commands.md](./useful-commands.md) file for more useful commands and info


## 💻 Tested Environment

* **Rancher Desktop:** 1.15.1 (Moby engine)
* **Colima:** 0.8.1
* **Docker Compose:** 2.29.1
* **OS:** macOS Sonoma 14.4.1 / Sequoia 15.4.1 (Apple Silicon)
