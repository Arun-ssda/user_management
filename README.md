# README

# UserManagement
A Ruby on Rails 8 application that enables user authentication and subscription management, integrated with Stripe for handling subscription lifecycle events through a state machine.

The Readme contains basic steps to start the application, overview of the models used and the interfaces used for communication.

## Key overviews

1. Ruby version = **3.4.3**, Rails version = **8.0.2**
2. Session management using **JWT tokens**
3. Passwords are hashed using **BCrypt**
4. Uses **state_machines-activerecord** for state transitions
5. Runs a simple Puma server on docker compose up

## Limitations
1. Stripe development account couldn't be created for individual users in India. So, Added a *postman collection* on the codebase with required set of event payloads. Variables have to be altered to trigger events accordingly.
2. No time dimension on subscriptions. Subscriptions are unlimited that it can be cancelled and subscribed any number of times.

## To start the application
```bash
docker compose up -d user_management
docker exec -it user_management bash
bin/rails db:create db:migrate db:seed
```

Application Root page - http://0.0.0.0:3000
## List of flows

### User login

Sample user creds ( from db seed)
```
email:    user1@gmail.com
password: user1
```

The password is hashed and validated using **Bcrypt** gem.
```ruby
### Sample snippet
> enc_password = BCrypt::Password.create("password")
> enc_password == BCrypt::Password.new("password")
> true
```

The user login is maintained using **JWT token** stored as cookies with 1 hour of expiry.


### Subscription creation

* Post login user dashboard will list the current subscriptions and list of available subscriptions.
* User can click on subscribe button to subscribe to a product.
* Subscription will start with *init* status

### Stripe webhooks

Webhooks are accessible on http://0.0.0.0:3000/webhooks/stripe_events

Currently, as required 3 events are supported:
1. customer.subscription.created
2. customer.subscription.deleted
3. invoice.payment_succeeded

#### 1. customer.subscription.created
 - Looks for the given subscription_id for the user with customer_id
 - Verifies whether the subscription available on the system matches with the product details on the payload 
 - Change the status of the subscription from init -> unpaid
 - Else, auto-creates subscription if user haven't subscribed yet with the given subscription ID

#### 2. customer.subscription.deleted
 - Looks for the given subscription_id for the user with customer_id
 - Verifies whether the subscription available on the system matches with the product details on the payload 
 - Change the status from [unpaid, paid] -> cancelled
 - Post this subscription reaches EOL

#### 3. invoice.payment_succeeded
 - Looks for the given subscription
 - Checks whether it is cancelled or already paid
 - Change ths status from [init, unpaid] -> paid

### EventProcessing
The events received via webhooks are:
1. Stored in **StripeEventRecord** and the record will be marked as received
2. The received event will then be validated and processed
3. Any error on the processing will make the record errored
4. Successful processing of the record will make it as processed and any future events with same event id and type will not be processed

Any Error in the event reception will lead to loss of event packet.

### EventLogging
All the events received will be logged in **StripeEventRecord**.
This is being done for the following purposes:
1. **async processing** - storing the payload enables the ability to process the record async
2. **Idempotency** - rejects the payload if the already processed based on the event_id and event_type. If the existing payload received is errored, new record will be created and processed again.
3. **trackability** - track events along with its payload with the statuses - [received, processed, errored]

### Security
1. CSRF will fail on webhooks controller and protected with null session always
```
  protect_from_forgery with: :null_session
```
2. Application level authentication using JWT
3. Uses *strong_parameters* before using params to prevent mass assignment
3. Rails Inbuild security features
    * *csrf_meta_tags* adds authenticity token for every form submit

### Evolution
1. The record processing should be made async decoupling event reception and processing
2. Event reception can be added to staging without any application processing to prevent any loss of packet during reception

#### Actual stripe Integration

When actual stripe integration is possible, the below steps to be done:
1. Change the stripe credentials in .env file to connect to the actual stripe account
2. Add stripe signature verification as part of webhook event reception
