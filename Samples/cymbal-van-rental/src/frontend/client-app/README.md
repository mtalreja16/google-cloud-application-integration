# Client App Walkthrough

We have built app for 3 personas

- Customer looking to Purchase a Van rental
- Agent who is going to Manage the reservation during walkthrough and returned
- Partners receiving the notification of inventory (coming soon…)

## Customer looking to Purchase a Van rental

Landing page - Integration-Demo/client-app/customer.html

![image10](https://user-images.githubusercontent.com/93729562/210857426-1fc751b6-6629-4843-83f0-10c9234ebbec.png)


Click on "Search Now"


![image9](https://user-images.githubusercontent.com/93729562/210857450-cdbad29d-23de-4dd7-8703-e4fcfc343d5b.png)


Click **Reserve** on desired Van


Fill out the reservation form and click on **confirm**

![image13](https://user-images.githubusercontent.com/93729562/210857497-7721ae21-b4a0-4f71-b6e3-84307fc01b22.png)


Once the reservation form is submitted, the notification will go to fullfilment center and they will confirm the availability of Van with configuration



## Agent - Managing the reservation


![22](https://user-images.githubusercontent.com/93729562/210857915-8eb9ba73-48ec-4047-8659-e9e71ecc0e1a.jpg)


When Agents approve it, customer will receive the email notification

![23](https://user-images.githubusercontent.com/93729562/210858068-206ef3f8-54f7-417a-bf08-36fa63c47a31.jpg)


Go to page /client-app/agent-search.html

![image4](https://user-images.githubusercontent.com/93729562/210858249-05df761e-9e3c-49c3-b1a5-b8454505ab43.png)


Click on **search** button

![image5](https://user-images.githubusercontent.com/93729562/210858326-e4e8deb1-4f5a-4552-92d3-cbb83d8dab98.png)


Click on the **"Van Pickup"** Link

Click on **Van Pickedup** button, this will triggered integration for van pickup and customer credit card will be charged

<img width="533" alt="image8" src="https://user-images.githubusercontent.com/93729562/210858404-759e8613-9267-4752-a0af-f2c1d5686d94.png">

Customer will also receive an email

<img width="746" alt="image7" src="https://user-images.githubusercontent.com/93729562/210858958-5887f423-9659-4307-9f12-25549de064f5.png">

When Customer returns the vehicle, go **"search"** again and click on **"Van Return"**

![image4](https://user-images.githubusercontent.com/93729562/210858249-05df761e-9e3c-49c3-b1a5-b8454505ab43.png)


Click on **Van Returned,** when van is returned customer will get and thank you email with summary and those complete full reservation demo

<img width="522" alt="image11" src="https://user-images.githubusercontent.com/93729562/210858667-093c0d37-56b3-43be-8dfd-380e5faf91e8.png">

Agent additionaly can click on checkbox for claims processing, this will trigger notification to claims department and integration will go in suspend until claims approve the damage.
