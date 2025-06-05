const express = require('express');
const app = express();
const port = 5000; 
const cors = require('cors');
const bodyParser = require('body-parser');
const sudo = require('sudo-prompt');

const { exec } = require('child_process');



// Middleware
app.use(bodyParser.json());
app.use(cors());
app.use(express.json());





let sudoAuthenticated = false;

// how to commands line use interface created 
app.post('/nmap', (req, res) => {
    const { command } = req.body;

    // Debugging: Log the command received
    console.log(`Received command: ${command}`);

    // Validate the command (basic example, improve for production use)
    if (!command.startsWith('nmap ')) {
        return res.status(400).send({ error: 'Invalid command' });
    }

    // Execute nmap command with sudo only if not authenticated yet
    if (!sudoAuthenticated) {
        // Prompt for sudo password
        sudo.exec('echo "sudo password prompt"', { name: 'Nmap' }, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error prompting for sudo password: ${stderr}`);
                return res.status(500).send({ error: 'Failed to authenticate with sudo' });
            }
            sudoAuthenticated = true; // Set authentication flag to true
            executeNmap(command, res); // Execute the actual nmap command
        });
    } else {
        executeNmap(command, res); // Execute the actual nmap command if already authenticated
    }
});

// Function to execute nmap command
function executeNmap(command, res) {
    // Execute nmap command with sudo
    exec(command, { name: 'Nmap' }, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing command: ${stderr}`);
            return res.status(500).send({ error: stderr });
        }
        console.log(`Command output: ${stdout}`);
        res.send({ output: stdout });
    });
}


// ip info 
app.get('/network-info', (req, res) => {
    exec('ifconfig', (error, stdout, stderr) => {
        if (error) {
            res.status(500).json({ error: stderr });
            return;
        }

        // Extract IP addresses from the ifconfig output
        const ipRegex = /inet\s(\d+\.\d+\.\d+\.\d+)/g;
        const ips = [];
        let match;
        while ((match = ipRegex.exec(stdout)) !== null) {
            ips.push(match[1]);
        }

        res.json({ data: ips });
    });
});

// Start the server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}/`);
});
