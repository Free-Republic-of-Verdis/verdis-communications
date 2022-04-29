importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: 'AIzaSyBsphs0mmZoy7oSR3jBDQQregOK7skXQcA',
    appId: '1:686272364376:web:8fc8358d4338495d236f2d',
    messagingSenderId: '686272364376',
    projectId: 'verdis-communications',
    authDomain: 'verdis-communications.firebaseapp.com',
    databaseURL: 'https://verdis-communications-default-rtdb.firebaseio.com',
    storageBucket: 'verdis-communications.appspot.com',
    measurementId: 'G-5WGE7QBPRW',
});
// Necessary to receive background messages:
const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
    console.log("onBackgroundMessage", m);
});