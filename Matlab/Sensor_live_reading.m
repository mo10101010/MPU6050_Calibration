% Clean up
if exist('s', 'var')
    clear s
end
delete(instrfind);

% --- Load Saved Offsets ---
load('mpu6050_offsets.mat');

% --- Connect ---
port = '/dev/ttyUSB0';
baudRate = 115200;

s = serialport(port, baudRate);
configureTerminator(s, "LF");
flush(s);
disp('Connected! Close the figure to stop and save.');
pause(2);
flush(s);

% --- Filter state ---
alpha = 0.1;
beta  = 0.9;
gx_lpf = 0; gy_lpf = 0; gz_lpf = 0;
ax_prev = 0; ay_prev = 0;
ax_hpf  = 0; ay_hpf  = 0;

% --- Buffer for plotting ---
N = 200;
ax_buf = zeros(N,1); ay_buf = zeros(N,1); az_buf = zeros(N,1);
gx_buf = zeros(N,1); gy_buf = zeros(N,1); gz_buf = zeros(N,1);

% --- Storage for saving ---
log_data = [];
timestamps = [];
t_start = tic;

% --- Setup Live Figure ---
figure('Name', 'MPU6050 Live Readings', 'NumberTitle', 'off');

subplot(2,1,1);
h_ax = plot(ax_buf, 'r'); hold on;
h_ay = plot(ay_buf, 'g');
h_az = plot(az_buf, 'b');
legend('ax','ay','az');
ylabel('g'); title('Accelerometer (calibrated)');
ylim([-2 2]); grid on;

subplot(2,1,2);
h_gx = plot(gx_buf, 'r'); hold on;
h_gy = plot(gy_buf, 'g');
h_gz = plot(gz_buf, 'b');
legend('gx','gy','gz');
ylabel('deg/s'); title('Gyroscope (low pass filtered)');
ylim([-10 10]); grid on;

% --- Live Read Loop ---
while ishandle(h_ax)
    line = strtrim(char(readline(s)));
    values = str2double(strsplit(line, ','));

    if numel(values) == 6 && ~any(isnan(values))

        % Timestamp
        t = toc(t_start);

        % Apply calibration
        ax = (values(1) - offsets.ax_bias) / 16384.0;
        ay = (values(2) - offsets.ay_bias) / 16384.0;
        az = (values(3) - offsets.az_bias) / 16384.0;
        gx = (values(4) - offsets.gx_bias) / 131.0;
        gy = (values(5) - offsets.gy_bias) / 131.0;
        gz = (values(6) - offsets.gz_bias) / 131.0;

        % Low pass filter on gyro
        gx_lpf = alpha * gx + (1 - alpha) * gx_lpf;
        gy_lpf = alpha * gy + (1 - alpha) * gy_lpf;
        gz_lpf = alpha * gz + (1 - alpha) * gz_lpf;

        % High pass filter on accel
        ax_hpf = beta * (ax_hpf + ax - ax_prev);
        ay_hpf = beta * (ay_hpf + ay - ay_prev);
        ax_prev = ax;
        ay_prev = ay;

        % Log data
        log_data = [log_data; t, ax, ay, az, gx_lpf, gy_lpf, gz_lpf];

        % Shift plot buffers
        ax_buf = [ax_buf(2:end); ax];
        ay_buf = [ay_buf(2:end); ay];
        az_buf = [az_buf(2:end); az];
        gx_buf = [gx_buf(2:end); gx_lpf];
        gy_buf = [gy_buf(2:end); gy_lpf];
        gz_buf = [gz_buf(2:end); gz_lpf];

        % Update plot safely
        try
            set(h_ax, 'YData', ax_buf);
            set(h_ay, 'YData', ay_buf);
            set(h_az, 'YData', az_buf);
            set(h_gx, 'YData', gx_buf);
            set(h_gy, 'YData', gy_buf);
            set(h_gz, 'YData', gz_buf);
            drawnow limitrate;
        catch
            break;  % Figure was closed, exit loop cleanly
        end

        % Console output
        fprintf('t=%6.2fs | Accel(g): X=%6.3f Y=%6.3f Z=%6.3f | Gyro(deg/s): X=%6.3f Y=%6.3f Z=%6.3f\n', ...
                 t, ax, ay, az, gx_lpf, gy_lpf, gz_lpf);
    end
end

% --- Cleanup ---
clear s;
disp('Disconnected. Saving data...');

% --- Check data before saving ---
fprintf('log_data size: %d rows x %d cols\n', size(log_data,1), size(log_data,2));

if isempty(log_data)
    disp('No data collected — nothing to save.');
else
    % --- Save to CSV ---
    header = {'Time_s','Accel_X_g','Accel_Y_g','Accel_Z_g','Gyro_X_dps','Gyro_Y_dps','Gyro_Z_dps'};

    % Make sure columns match
    if size(log_data, 2) == numel(header)
        T = array2table(log_data, 'VariableNames', header);

        % CSV
        writetable(T, 'mpu6050_readings.csv');
        disp('CSV saved: mpu6050_readings.csv');

        % Excel
        writetable(T, 'mpu6050_readings.xlsx');
        disp('Excel saved: mpu6050_readings.xlsx');

        % MAT
        save('mpu6050_readings.mat', 'log_data', 'header');
        disp('MAT saved: mpu6050_readings.mat');
    else
        fprintf('Column mismatch: log_data has %d cols but header has %d names\n', ...
                 size(log_data,2), numel(header));
        % Save raw without headers as fallback
        writematrix(log_data, 'mpu6050_readings_raw.csv');
        disp('Saved raw CSV without headers as fallback.');
    end
end

disp('Done!');
