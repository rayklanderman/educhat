importScripts("https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js");

firebase.initializeApp({
    // Your web app's Firebase configuration will go here
    // This will be replaced with actual values during deployment
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
