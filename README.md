# Bluetooth Interfacing with 8051 Microcontroller

## Overview

This project is a multi-functional embedded system developed using the AT89S52 (8051) microcontroller for the course **EEE 4706 – Microcontroller Based System Design Lab**.

The system integrates Bluetooth communication, LCD interfacing, relay control, Morse code transmission, encryption/decryption, password protection, and PWM-based LED brightness control using low-level 8051 Assembly programming.

The project was designed and simulated in Proteus and later implemented on physical hardware for testing and validation.

---

## Features

### Bluetooth-Controlled 8 LED System

* Wireless ON/OFF control of 8 LEDs
* Individual LED selection
* Simultaneous LED control
* Real-time command handling through UART communication

### Morse Code Transmission

* Morse code generation using LEDs
* Dot and dash timing implementation
* LCD displays current symbols and decoded characters
* Bluetooth-based message input

### Relay-Based Home Automation

* Control of 2 relay modules through Bluetooth
* Simulates remote switching of appliances/lights
* Relay status displayed on LCD

### Caesar Cipher Decryption

* Receives encrypted text through Bluetooth
* Decrypts messages using user-defined shift key
* Displays decrypted text on LCD

### Password Protection

* PIN-based authentication using keypad input
* LCD feedback for user access
* Lockout mechanism after multiple incorrect attempts

### PWM LED Brightness Control

* Adjustable LED brightness using PWM
* Brightness increase/decrease through Bluetooth commands
* Demonstrates analog-style control using digital hardware

---

## Hardware Components

* AT89S52 (8051) Microcontroller
* HC-05 Bluetooth Module
* 16x2 LCD Display
* 4x4 Matrix Keypad
* Relay Modules
* LEDs
* 7-Segment Display
* Push Buttons
* Crystal Oscillator
* Breadboard / PCB
* 5V Power Supply

---

## Communication & Interfaces

* UART Communication
* Interrupt-Driven Serial Communication
* LCD Interfacing
* Keypad Scanning
* PWM Signal Generation
* Relay Control
* Hardware-Level Port Management

---

## Programming Language

* 8051 Assembly Language

---

## Software & Tools Used

* Proteus
* Keil µVision
* Embedded Systems Design
* UART Communication
* Hardware Debugging

---

## Proteus Circuit Simulation

The following image shows the complete Proteus-based simulation of the embedded Bluetooth control system.

![Proteus Simulation](Proteus%20Circuit%20Simulation.jpg)

---

## Mode Selection Interface

This hardware setup demonstrates the running condition of the system while selecting different operating modes using the keypad and LCD interface.

![Mode Selection](Selecting%20the%20Mode%20of%20Operation.jpg)

---

## Password Protection Hardware

The following image demonstrates the password authentication system implemented in hardware for secure access control.

![Hardware Setup](Password%20Protection%20in%20Hardware.png)

---

## Working Principle

The HC-05 Bluetooth module communicates with the AT89S52 microcontroller through UART serial communication. Commands sent from a smartphone are received using interrupt-driven serial routines and processed according to the selected operating mode.

The system supports:

* Relay switching
* Morse code LED transmission
* Encrypted text decryption
* PWM-based LED brightness control
* Password-protected access

LCD feedback is provided in real time for all operations.

