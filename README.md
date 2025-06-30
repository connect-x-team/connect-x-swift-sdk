# ConnectX Mobile SDK

The **ConnectX Mobile SDK** is a Swift library designed to simplify the integration of ConnectX's tracking and data management features into your mobile applications. It provides functionalities for tracking events, managing user data, and interacting with backend APIs, ensuring seamless user analytics and experience tracking.

---

## Features

- **User Event Tracking**: Track user actions, behaviors, and interactions within your app.
- **Create Customer**: Identify and manage user details across sessions.
- **Open Ticket**: Open support tickets programmatically.
- **Create or Update Custom Records**: Create and edit records in bulk.
- **Get Unknown ID**: Generates and returns a unique identifier.

---

## Getting started

### Prerequisites
- A valid **ConnectX API Token** and **Organize ID** are required for initialization.

### Installation
Run the following command to add the package to your project:

```bash
https://github.com/connect-x-team/connect-x-swift-sdk.git
```

In Xcode: Go to File → Add Packages -> Enter the repository URL -> Select the latest version and click Add Package

OR

```bash
.package(url: "https://github.com/connect-x-team/connect-x-swift-sdk.git", from: "x.x.x")
```

Install with a Swift Package Manager manifest

## Usage

### 1. Import the Library

```swift
import ConnectXMobileSdk
```


### 2. Initialize the SDK

Before using any SDK methods, initialize it with your token and organize ID.
Note: You can generate the YOUR_API_TOKEN from [Connect-X](https://app.connect-x.tech/) by navigating to:
Organization Settings → SDK Tracking.

```swift
ConnectXManager.shared.initialize(
    token: "YOUR_API_TOKEN",
    organizeId: "YOUR_ORGANIZE_ID",
    env: "YOUR_ENV" //optional
    )
```

### 3. Track Events

```swift
let eventBody: [String: Any] = [
    "cx_title": "YOUR_EVENT_NAME", 
    "cx_event": "YOUR_EVENT", 
    "cx_type": "YOUR_TYPE"
] // ... Other Activity Field
ConnectXManager.shared.cxTracking(body: eventBody) { success, error, response in
    if success {
        print("Tracking event sent successfully.")
    } else if let error = error {
        print("Failed to send tracking event: \(error)")
    }
}
```

### 4. Create Customer

```swift
ConnectXManager.shared.cxIdentify(
    body: [
        "key": "cx_email", 
        "customers": [
            "cx_Name": CUSTOMER_NAME,
            "cx_firstName": CUSTOMER_FIRST_NAME,
            "cx_mobilePhone": CUSTOMER_MOBILE_PHONE,
            "cx_email": CUSTOMER_EMAIL]
            //... Other Customer Field
        ],
        "tracking": [ // Optional
            "cx_title": "YOUR_EVENT_NAME", 
            "cx_event": "YOUR_EVENT", 
            "cx_type": "YOUR_TYPE"
            // ... Other Activity Field
        ],
        "form": [ // Optional
            "cx_subject": "YOUR_SUBJECT", 
            "cx_desc":"YOUR_DESC"
            // ... Other Form Field.
        ], 
        "options": [ // Optional
            "updateCustomer": true, // Enable/Disable Customer Data Update
            "customs": [
                // For adding values in the Object that you want to reference with the Customer Object.
                ["customObjectA": ["cx_Name": "Keyword"]],
                ["customObjectB": ["cx_Name": "Keyword"]]
            ],
            "updateSomeFields": [
                // For adding cases where you want to update some values in the Customers Object.
                "bmi": 25,
                "weight": 55
            ]
        ]
]) { success, error, response in
    if success {
        print("Identify event sent successfully.")
    } else if let error = error {
        print("Error identifying: \(error)")
    }
}
```

### 5. Open Ticket

```swift
ConnectXManager.shared.cxOpenTicket(body: [
    "key": "cx_Name",
    "customers": [
        "cx_Name": name,
        "cx_firstName": fitstName,
        "cx_phone": "0000000000",
        "cx_mobilePhone": "0000000000",
        "cx_email": customerEmail
    ],
    "ticket": [
        "cx_subject": "test email",
        "cx_socialAccountName": "xxxx@hotmail.com",
        "cx_socialContact": "xxxx@hotmail.com",
        "cx_channel": "email",
        "email": [
            "text": "from mobile app",
            "html": "<b>\(content)</b>"
        ]
    ],
    "lead": [
        "cx_email": "xxxx@hotmail.com",
        "cx_channel": "test_connect_email"
    ],
    "customs": [
        [
            "customObjectA": ["cx_Name": "Test"]
        ],
        [
            "customObjectB": ["cx_Name": "Test"]
        ]
    ]
]) { success, error, response in
    if success {
        print("Ticket opened successfully.")
    } else if let error = error {
        print("Error opening ticket: \(error)")
    }
}
```

### 6. Create or Update Custom Records

To create a new custom object, you must generate a unique referenceId to identify the record. If you pass a docId, the object is updated instead of being created.

```swift
ConnectXManager.shared.cxCreateRecord(objectName: objectName, bodies: [ // limit 200 rows
    [
        "attributes": ["referenceId": "UNIQUE_ID"], Replace with your unique ID generation logic
        "cx_Name": cxName,
        "docId": docId // Pass null for create mode; pass a valid ID for edit mode
    ]
]) { success, error, response in
    if success && response != nil {
        print("Record created successfully.")
        print(response ?? "no response")
        if let resultString = String(data: response!, encoding: .utf8) {
            print("Response as String: \(resultString)")
        } else {
            print("Could not convert data to a UTF-8 string.")
        }
    } else if let error = error {
        print("Error creating record: \(error)")
    }
}
```

### 7. Get Unknown ID

This method generates and returns a unique identifier.

```swift
ConnectXManager.shared.getUnknownId { cookie in
    if let cookie = cookie {
        print("Received cookie: \(cookie)")
    } else {
        print("Failed to fetch cookie")
    }
}
```

## License

[![Apache License](https://img.shields.io/badge/License-Apache-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
