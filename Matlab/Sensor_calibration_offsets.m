% Clean up any existing connections
if exist('s', 'var')
    clear s
end
delete(instrfind);

% --- Connect ---
port = '/dev/ttyUSB0';
baudRate = 115200;

s = serialport(port, baudRate);
configureTerminator(s, "LF");
flush(s);
disp('Connected!');

% --- Flush garbage lines first ---
disp('Flushing buffer, wait 2 seconds...');
pause(2);
flush(s);
disp('Starting data collection. Keep sensor FLAT and STILL, component side UP...');

% --- Collect Data ---
numSamples = 1000;
data = zeros(numSamples, 6);
collected = 0;

while collected < numSamples
    line = strtrim(char(readline(s)));
    values = str2double(strsplit(line, ','));
    if numel(values) == 6 && ~any(isnan(values))
        collected = collected + 1;
        data(collected, :) = values;
        if mod(collected, 100) == 0
            fprintf('Collected %d / %d samples...\n', collected, numSamples);
        end
    end
end

disp('Data collection complete.');
clear s;

% --- Raw means for debugging ---
ax_raw = data(:,1);  ay_raw = data(:,2);  az_raw = data(:,3);
gx_raw = data(:,4);  gy_raw = data(:,5);  gz_raw = data(:,6);

fprintf('\n--- Raw Means ---\n');
fprintf('Accel -> X: %.1f  Y: %.1f  Z: %.1f (LSB)\n', mean(ax_raw), mean(ay_raw), mean(az_raw));
fprintf('Gyro  -> X: %.1f  Y: %.1f  Z: %.1f (LSB)\n', mean(gx_raw), mean(gy_raw), mean(gz_raw));

% --- Compute Biases ---
% Board flat, component side up: gravity = -Z = -16384 LSB
ONE_G = 16384.0;
DEG_PER_SEC = 131.0;

ax_bias = mean(ax_raw);           % expected: 0
ay_bias = mean(ay_raw);           % expected: 0
az_bias = mean(az_raw) + ONE_G;   % expected: -16384, so add ONE_G

gx_bias = mean(gx_raw);
gy_bias = mean(gy_raw);
gz_bias = mean(gz_raw);

fprintf('\n--- Calibration Offsets ---\n');
fprintf('Accel bias -> X: %.2f  Y: %.2f  Z: %.2f (LSB)\n', ax_bias, ay_bias, az_bias);
fprintf('Gyro  bias -> X: %.2f  Y: %.2f  Z: %.2f (LSB)\n', gx_bias, gy_bias, gz_bias);

% --- Apply Corrections ---
ax_cal = (ax_raw - ax_bias) / ONE_G;
ay_cal = (ay_raw - ay_bias) / ONE_G;
az_cal = (az_raw - az_bias) / ONE_G;   % should now read -1g
gx_cal = (gx_raw - gx_bias) / DEG_PER_SEC;
gy_cal = (gy_raw - gy_bias) / DEG_PER_SEC;
gz_cal = (gz_raw - gz_bias) / DEG_PER_SEC;

fprintf('\n--- Calibrated Means (should be 0, 0, -1 for accel) ---\n');
fprintf('Accel -> X: %.4f  Y: %.4f  Z: %.4f (g)\n', mean(ax_cal), mean(ay_cal), mean(az_cal));
fprintf('Gyro  -> X: %.4f  Y: %.4f  Z: %.4f (deg/s)\n', mean(gx_cal), mean(gy_cal), mean(gz_cal));

% --- Save Offsets ---
offsets.ax_bias = ax_bias;
offsets.ay_bias = ay_bias;
offsets.az_bias = az_bias;
offsets.gx_bias = gx_bias;
offsets.gy_bias = gy_bias;
offsets.gz_bias = gz_bias;
save('mpu6050_offsets.mat', 'offsets');
disp('Offsets saved to mpu6050_offsets.mat');

% --- Plot ---
figure;
subplot(2,1,1);
plot([ax_cal, ay_cal, az_cal]);
legend('ax','ay','az'); ylabel('g');
title('Accelerometer Calibrated (az should be at -1g)');
grid on;

subplot(2,1,2);
plot([gx_cal, gy_cal, gz_cal]);
legend('gx','gy','gz'); ylabel('deg/s');
title('Gyroscope Calibrated (all should be near 0)');
grid on;
