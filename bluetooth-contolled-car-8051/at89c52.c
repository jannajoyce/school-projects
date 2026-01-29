#include <reg51.h>
// Define motor control pins
sbit LM1 = P2^0; // Left motor forward control
sbit LM2 = P2^1; // Left motor backward control
sbit RM1 = P2^2; // Right motor forward control
sbit RM2 = P2^3; // Right motor backward control
// Define light control pins
sbit Front_light1 = P2^4; // Front light 1
sbit Front_light2 = P2^5; // Front light 2
sbit Back_light1 = P2^6; // Back light 1
sbit Back_light2 = P2^7; // Back light 2
// Define debugging LED and button pins
sbit Debug_LED = P1^0; // Debugging LED to indicate data reception
sbit Button1 = P3^6; // Push button 1 for forward
sbit Button2 = P3^7; // Push button 2 for backward
sbit Button3 = P1^5; // Push button 3 for left
sbit Button4 = P1^6; // Push button 4 for right

// Function declarations
void delay_ms(unsigned int a);
void debounce();
void uart_init();
void uart_transmit(unsigned char byte);
unsigned char uart_receive();
void process_command(unsigned char command);
void stop_all();
void main()
{
unsigned char command;
// Initialize UART
uart_init();
// Initialize all motor control pins to low
LM1 = 0;
LM2 = 0;
RM1 = 0;
RM2 = 0;
// Initialize light control pins (assuming active low)
Front_light1 = 1; // Initially off
Front_light2 = 1; // Initially off
Back_light1 = 1; // Initially off
Back_light2 = 1; // Initially off
// Turn off the debugging LED initially
Debug_LED = 0;
while(1)
{
// Check for Bluetooth command
if (RI) // If a Bluetooth command is received
{
command = uart_receive();
process_command(command);
delay_ms(20);
Debug_LED = 0; // Turn off the debugging LED after processing the command
stop_all();
}
else // If no Bluetooth command, check buttons
{
// Check push button states with debounce
if (Button1 == 0) // Assuming active low push button
{
debounce();

if (Button1 == 0)
{
process_command('F'); // Process as forward command
delay_ms(20);
Debug_LED = 0;
stop_all();
}
}
if (Button2 == 0) // Assuming active low push button
{
debounce();
if (Button2 == 0)
{
process_command('B'); // Process as backward command
delay_ms(20);
Debug_LED = 0;
stop_all();
}
}
if (Button3 == 0) // Assuming active low push button
{
debounce();
if (Button3 == 0)
{
process_command('L'); // Process as left command
delay_ms(20);
Debug_LED = 0;
stop_all();
}
}
if (Button4 == 0) // Assuming active low push button
{
debounce();
if (Button4 == 0)
{
process_command('R'); // Process as right command
delay_ms(20);
Debug_LED = 0;
stop_all();
}
}
}
}
}

// UART initialization
void uart_init()
{
TMOD = 0x20; // Timer1 in Mode2 (8-bit auto-reload)
// For 12 MHz crystal and 9600 baud rate
TH1 = 0xFD; // Baud rate 9600 for 12 MHz crystal
SCON = 0x50; // Mode1: 8-bit UART, enable receiver
TR1 = 1; // Start Timer1
}
// UART transmit function
void uart_transmit(unsigned char byte)
{
SBUF = byte;
while (!TI);
TI = 0;
}
// UART receive function
unsigned char uart_receive()
{
while (!RI);
RI = 0;
return SBUF;
}
// Process received command
void process_command(unsigned char command)
{
Debug_LED = 1; // Turn on the debugging LED to indicate data reception
switch(command)
{
case 'F': // Forward movement and front lights on
Front_light1 = 0; // Turn on front lights
Front_light2 = 0; // Turn on front lights
LM1 = 1;
LM2 = 0;
RM1 = 1;
RM2 = 0;
break;
case 'B': // Backward movement and back lights on
Back_light1 = 0; // Turn on back lights
Back_light2 = 0; // Turn on back lights
LM1 = 0;
LM2 = 1;
RM1 = 0;

RM2 = 1;
break;
case 'L': // Left movement
Front_light1 = 1; // Turn off front lights
Front_light2 = 1; // Turn off front lights
Back_light1 = 1; // Turn off back lights
Back_light2 = 1; // Turn off back lights
LM1 = 0; // Stop left motor
LM2 = 0;
RM1 = 1; // Move right motor forward
RM2 = 0;
break;
case 'R': // Right movement
Front_light1 = 1; // Turn off front lights
Front_light2 = 1; // Turn off front lights
Back_light1 = 1; // Turn off back lights
Back_light2 = 1; // Turn off back lights
LM1 = 1; // Move left motor forward
LM2 = 0;
RM1 = 0; // Stop right motor
RM2 = 0;
break;
default:
// Invalid command
break;
}
}
// Stop all motors and turn off lights
void stop_all()
{
LM1 = 0;
LM2 = 0;
RM1 = 0;
RM2 = 0;
Front_light1 = 1;
Front_light2 = 1;
Back_light1 = 1;
Back_light2 = 1;
}
// Simple delay function to create a millisecond delay
void delay_ms(unsigned int a)
{
unsigned int i, j;
for (i = 0; i < a; i++)
{
for (j = 0; j < 82; j++) // Adjusted for 8 MHz crystal

{
// Do nothing, just burn time
}
}
}
// Debounce function to handle mechanical button bounce
void debounce()
{
delay_ms(20); // Simple debounce delay of 20 ms
}