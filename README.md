# MPU6050_Calibration
##Parts needed
 - Development board as Arduino or ESP-32
 - MPU6050, it has 6 axis, 3 gyroscope + 3 accelerometer
- - -
##Software needed
 - Arduino IDE
 - MATLAB
- - -
##Steps
 - Inside IDE: Compile and upload the sketch to print the csv to serial.
 - Make sure that you close IDE that it doesn't infere with MATLAB.
 - Inside MATLAB: First use the Matlab file to get offesets.
 - After you get offsets import them to the second file then run it.
 - Terminal will display the live redings, also a graphs inside the figure.
 - When you close the figure, the readings will be saved inside an excel and csv files.
   
