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
 - Clone the files in the same order as it is here.
 - Open IDE and setup board connection and port, keep the port with you.
 - run csv_to_serial.ino, it will outpout gyro and accel readings live as csv.
 - Make sure that you close IDE that it doesn't infere with MATLAB port connection.
 - Open the Matlab folder inside MATLAB, make sure that you set the correct port inside code.
 - Before you run anything, fix the sensor with a tape on a perfect flat surface.
 - First run sensor_calibrate_values.m, it will give you offset and save it to a mat file.
 - After you get offsets, they will be directly imported when you run the second file.
 - run sesnor_live_values.m, it will give you the live reading in the script and the figure.
 - When you close the figure, the readings will be saved inside an excel and csv files.
- - -


   
