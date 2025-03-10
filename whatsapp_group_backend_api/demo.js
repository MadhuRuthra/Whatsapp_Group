const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const fse = require('fs-extra');
const fs = require('fs');

// const SESSION_FILE_PATH = './session.json';
const myGroupName = 'TESTING'; // Replace with your actual group name
const messageToSend = 'Hello, this is a test message!';

var chrome_path = '';
// Initialize client
const client = new Client({
    restartOnAuthFail: true,
    takeoverOnConflict: true,
    takeoverTimeoutMs: 0,
    puppeteer: {
        // handleSIGINT: false,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu'
        ],
        executablePath: chrome_path,
    },
    authStrategy: new LocalAuth({ clientId: 918838964597 })
});
console.log(client);
// Event emitted when the client is authenticated
client.on('authenticated', (session) => {
    try {
        console.log('Authenticated. Saving session.');
        // Check if the session object exists
        if (session) {
            console.log('Session:', session);

        } else {
            console.error('Invalid session data received.');
        }
    } catch (error) {
        console.error('Error:', error);
    }
});



// Event emitted when a QR code is generated
client.on('qr', (qrCodeString) => {
    console.log('QR Code generated. Scan it to log in.');
    qrcode.generate(qrCodeString, { small: true });
});

// Initialize the client
client.initialize();

// Event emitted when the client is ready
client.on('ready', async () => {
    var qr_number = client.info.wid.user;
    console.log(qr_number);
    if (fs.existsSync(`./.session_copy/session-${qr_number}`)) {
        console.log("if")
        fs.rmdirSync(`./.session_copy/session-${qr_number}`, { recursive: true })
    } else {
        // console.log("else");
        // fs.mkdirSync(`./.wwebjs_auth/session-${qr_number}`, { recursive: true });
    }
    if (fs.existsSync(`./.wwebjs_auth/session-${qr_number}`)) {
        // fs.rmdirSync(`./.wwebjs_auth/session-${sender_numbers[c]}`, { recursive: true })
        console.log("another if")

        try {
            console.log("try");
            fse.copySync(`./.wwebjs_auth/session-${qr_number}`, `./session_copy/session-${qr_number}`, { overwrite: true | false })
        } catch (err) {
            console.error(err)
        }
    }
    console.log('[Client is ready]');
    sendMessageToGroup(myGroupName);
});

// Event emitted when the client is disconnected
client.on('disconnected', async (reason) => {
    console.error('Client disconnected. Reason:', reason);
    // Destroy and reinitialize the client when disconnected
    await client.destroy();
});

// Function to send a message to a specified group
async function sendMessageToGroup(groupName) {
    console.log("sendMessageToGroup");
    console.log('Sending message to group:', groupName);

    try {
        // Wait for the client to be ready
        await new Promise(resolve => setTimeout(resolve, 5000));

        // Get the list of chats
        const chats = await client.getChats();
        // console.log(chats);
        // Find the group by name
        const group = chats.find(chat => chat.isGroup && chat.name.toLowerCase() === groupName.toLowerCase());
        // console.log(group);

        if (group) {
            // Send the message to the group
            const response = await group.sendMessage(messageToSend);
            console.log('Message sent successfully to the group. Response:', response);
        } else {
            console.error('Group not found.');
        }
    } catch (error) {
        console.error('Error sending message:', error);
    }
}



// const { Client, LocalAuth } = require('whatsapp-web.js');
// const qrcode = require('qrcode-terminal');
// const fse = require('fs-extra');
// const fs = require('fs');

// const myGroupName = 'TESTING'; // Replace with your actual group name
// const messageToSend = 'Hello, this is a test message!';

// // Function to authenticate using QR code
// async function authenticateWithQRCode() {
//     return new Promise((resolve, reject) => {
//         const client = new Client();

//         client.on('authenticated', (session) => {
//             console.log('Authenticated. Saving session.');
//             resolve(session);
//         });

//         client.on('qr', (qrCodeString) => {
//             console.log('QR Code generated. Scan it to log in.');
//             qrcode.generate(qrCodeString, { small: true });
//         });

//         client.initialize();
//     });
// }

// const client = new Client({
//     puppeteer: {
//         args: ['--no-sandbox']
//     },
//     authStrategy: new LocalAuth(authenticateWithQRCode)
// });

// // Event emitted when the client is ready
// client.on('ready', async () => {
//     var qr_number = client.info.wid.user;
//     console.log(qr_number);
//     if (fs.existsSync(`./.session_copy/session-${qr_number}`)) {
//         console.log("if")
//         fs.rmdirSync(`./.session_copy/session-${qr_number}`, { recursive: true })
//     } else {
//         // console.log("else");
//         // fs.mkdirSync(`./.wwebjs_auth/session-${qr_number}`, { recursive: true });
//     }
//     if (fs.existsSync(`./.wwebjs_auth/session-${qr_number}`)) {
//         // fs.rmdirSync(`./.wwebjs_auth/session-${sender_numbers[c]}`, { recursive: true })
//         console.log("another if")

//         try {
//             console.log("try");
//             fse.copySync(`./.wwebjs_auth/session-${qr_number}`, `./session_copy/session-${qr_number}`, { overwrite: true | false })
//         } catch (err) {
//             console.error(err)
//         }
//     }
//     console.log('[Client is ready]');
//     sendMessageToGroup(myGroupName);
// });

// // Event emitted when the client is disconnected
// client.on('disconnected', async (reason) => {
//     console.error('Client disconnected. Reason:', reason);
//     // Destroy and reinitialize the client when disconnected
//     await client.destroy();
// });

// // Function to send a message to a specified group
// async function sendMessageToGroup(groupName) {
//     console.log('Sending message to group:', groupName);

//     try {
//         // Wait for the client to be ready
//         await new Promise(resolve => setTimeout(resolve, 5000));

//         // Get the list of chats
//         const chats = await client.getChats();

//         // Find the group by name
//         const group = chats.find(chat => chat.isGroup && chat.name.toLowerCase() === groupName.toLowerCase());

//         if (group) {
//             // Send the message to the group
//             const response = await group.sendMessage(messageToSend);
//             console.log('Message sent successfully to the group. Response:', response);
//         } else {
//             console.error('Group not found.');
//         }
//     } catch (error) {
//         console.error('Error sending message:', error);
//     }
// }
