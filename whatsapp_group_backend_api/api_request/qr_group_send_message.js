const { Client, LocalAuth } = require('whatsapp-web.js');
const qrCode = require('qrcode-terminal');

const SESSION_FILE_PATH = './session.json';
const myGroupName = 'TESTING'; // Replace with your actual group name
const messageToSend = 'Hello, this is a test message!';

// Use LocalAuth as the auth strategy
const auth = new LocalAuth({
  sessionFile: SESSION_FILE_PATH,
  sessionTimeout: 86400, // 1 day in seconds
});

const client = new Client({
  auth: auth,
  puppeteer: {
    args: ['--no-sandbox'],
  },
});

// Save session on login
client.on('authenticated', (session) => {
  console.log('Authenticated. Saving session.');
  try {
    // Check if the session data is valid
    if (session) {
      require('fs').writeFileSync(SESSION_FILE_PATH, JSON.stringify(session)); // Save session manually
    } else {
      console.error('Invalid session data received.');
    }
  } catch (error) {
    console.error('Error saving session:', error);
  }
});

// Event emitted when a QR code is generated
client.on('qr', (qrCodeString) => {
  console.log('QR Code generated. Scan it to log in.');
  qrCode.generate(qrCodeString, { small: true });
});

// Event emitted when the client is ready
client.on('ready', () => {
  console.log('Client is ready.');

  // Call the function to send a message after the client is ready
  setInterval(() => {
    // Periodically call some library method to keep the client active
    client.getConnectionState()
      .then((state) => {
        if (state === 'CONFLICT') {
          console.log('Conflict detected. Please restart the application.');
        } else if (state === 'UNPAIRED') {
          console.log('Client is unpaired. Please restart the application.');
        }
      })
      .catch((error) => {
        console.error('Error checking connection state:', error);
      });
  }, 4 * 60 * 60 * 1000); // Every 4 hours

  // Call the function to send a message to the group
  sendMessageToGroup(myGroupName);
});

// Event emitted when a message is received
client.on('message', (message) => {
  console.log(`Received message in group ${message.chatId._serialized}: ${message.body}`);
});

// Event emitted when the client is disconnected
client.on('disconnected', (reason) => {
  console.log('Client disconnected. Reason:', reason);
});

// Event emitted when authentication fails
client.on('auth_failure', (msg) => {
  console.error('Authentication failure:', msg);
});

// Log in to WhatsApp Web
client.initialize();

// Function to send a message to a WhatsApp group
async function sendMessageToGroup(groupName) {
  console.log("Sending message");
  console.log(`Sending message to group: ${groupName}`);

  try {
    // Wait for the client to be ready
    await new Promise(resolve => setTimeout(resolve, 5000)); // Adjust the delay as needed

    // const messageToSend = 'Hello, this is a test message!';

    const chats = await client.getChats();
    const group = chats.find(chat => chat.isGroup && chat.name.toLowerCase() === groupName.toLowerCase());

    if (group) {
      const response = await group.sendMessage(messageToSend);
      console.log(JSON.stringify(response) + " response");
      console.log('Message sent successfully to the group');
    } else {
      console.error('Group not found.');
    }
  } catch (error) {
    console.error('Error sending message:', error);
  } finally {
    // Do not destroy the client after sending the message to keep it active
    // await client.destroy();
  }
}
