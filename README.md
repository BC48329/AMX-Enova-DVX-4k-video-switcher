# AMX Enova DVX 4K – Open IoT Integration Project

## Overview

This project aims to make the **AMX Enova DVX 4K series of presentation switchers** easier to integrate into modern, open-source automation and IoT ecosystems.

The AMX Enova DVX 4K is an all-in-one professional audio/video presentation switcher and control platform designed for conference rooms, classrooms, boardrooms, and other integrated AV environments.

Unlike a conventional HDMI matrix switcher, the DVX combines video switching, audio routing, signal processing, amplification, and system control into a single rack-mounted platform.

This repository serves as a centralized collection of documentation, programming references, command structures, scripts, configuration examples, and other useful resources for developing third-party integrations and controlling the DVX outside of a traditional proprietary AMX control environment.

The goal is to make these capabilities accessible through open and widely supported platforms such as:

- Node-RED
- MQTT
- Home Assistant
- Custom web interfaces
- Python applications
- JavaScript / Node.js applications
- Other IP-based automation and control systems

The intention is to extend the useful life of professional AV hardware by making it easier to incorporate into flexible, modern automation environments.

## Hardware Overview

DVX-2265-4K
DVX-3266-4K

## Project Goals

The primary objective is to document and expose the DVX's capabilities in a way that allows third-party systems to interact with it without requiring a complete AMX control system.

Rather than developing another proprietary control environment, this project focuses on reusable resources and standardized communication methods.

### 1. Document the Control Interface

Collect and organize the information necessary to communicate with the DVX, including:

- Network communication methods
- Available control protocols
- Command syntax and formatting
- Device addressing and connection requirements
- Feedback and status reporting
- Available switching and configuration commands
- Serial communication interfaces
- API and programming references

### 2. Provide Reusable Control Resources

Develop a collection of reusable examples and resources that can be incorporated into other projects.

These may include:

- Command reference files
- How-To connect documentation
- Communication scripts
- Example control sequences
- Input/output mapping references
- Status polling examples
- Feedback parsing examples
- Configuration templates
- Integration examples

### 3. Enable Open IoT Integration

Make it possible to connect the DVX to commonly available automation platforms.

For example, a Node-RED installation could communicate with the switcher over Ethernet, translate commands into MQTT messages, and expose its functions to a Home Assistant installation or a custom web dashboard.

The goal is to separate the underlying hardware communication from the user interface or automation platform.

This allows the same control resources to be reused across different applications.

## Repository Contents

This repository is intended to act as a central reference library for the AMX Enova DVX 4K platform.

Resources are organized around the following areas:

### Documentation

Technical documentation and reference material relating to the switcher that can't be found easily through the manufactures website.

### Commands and Protocols

A collection of documented commands and communication examples used to interact with the DVX.

The objective is to establish a reusable command reference that developers can use when creating their own integrations.

### Scripts and Examples

Working examples demonstrating how to communicate with and control the switcher.

These resources may include:

- TCP/IP communication examples
- Serial communication examples
- Command transmission scripts
- Response parsing
- Device status monitoring
- Switching and routing examples

### Node-RED Integration

Examples and resources for implementing the DVX within Node-RED.

Node-RED provides a convenient way to connect the switcher to other networked devices, automation systems, and messaging platforms.

Potential applications include:

- Selecting video sources
- Switching audio destinations
- Controlling audio levels
- Monitoring system status
- Building browser-based control interfaces
- Integrating with MQTT
- Connecting to Home Assistant

### Configuration and Reference Files

Supporting files used to simplify development and implementation.

These may include device configurations, command definitions, input/output maps, JSON examples, and other reusable resources.

## Open IoT Architecture

The intended architecture is based on keeping the DVX communication layer independent of the automation platform.

This architecture allows multiple systems to interact with the same hardware without requiring each application to independently implement the DVX communication protocol.

It also makes it possible to replace or expand the user interface without rewriting the underlying device integration.

## Intended Applications

Some examples of what this project could enable:

- Integrating legacy professional AV equipment into Home Assistant.
- Building custom browser-based AV control panels.
- Creating MQTT-controlled audio/video switching systems.
- Incorporating the DVX into whole-building automation.
- Developing automated room control systems.
- Connecting AV equipment to other IoT devices and services.
- Monitoring and controlling equipment through Node-RED dashboards.
- Reusing existing AMX hardware in installations that do not use an AMX control processor as the primary automation platform.

## Compatibility

The primary focus is the AMX Enova DVX 4K family.

Initial reference models:

- DVX-2265-4K
- DVX-3266-4K


## Contributing

Contributions, documentation, tested commands, working scripts, and integration examples are welcome.

Useful contributions include:

- Verified control commands
- Protocol documentation
- Working Node-RED flows
- Python and JavaScript examples
- MQTT integration examples
- Device configuration files
- Troubleshooting information
- Additional model compatibility information

When possible, contributions should include the hardware model, firmware version, communication method, and a description of how the example was tested.

The objective is to build a practical, community-supported reference that makes these devices easier to understand, control, and integrate.


## AI Disclosure

Some of the code and documents in this repo have been developed with the assistance of AI.


## Disclaimer

This is an independent integration project.

It is not affiliated with, endorsed by, or supported by AMX or HARMAN Professional Solutions.

AMX, Enova, NetLinx, DXLink, and related product names are trademarks of their respective owners.

All manufacturer documentation and trademarks remain the property of their respective owners.

---



**Project Philosophy:** Make professional AV hardware accessible, reusable, and interoperable through open communication standards and community-developed integration tools.
