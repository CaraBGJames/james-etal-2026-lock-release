%% Gate Lift Speed Analyser
% Loads a lock-release experiment video, lets you interactively select
% the gate columns, then tracks the gate edge through time and computes
% lift speed.
%
% Requirements: Image Processing Toolbox
% Usage: just run the script, follow the prompts.

clear; clc; close all;

%% ── 1. Load video ────────────────────────────────────────────────────────

exp_name    ='example_vid';
folder_path = 'PATH_TO_RAW_VIDEOS_HERE';;
vid_file_path = strcat(folder_path, exp_name, '.MP4');
vid = VideoReader(vid_file_path);

fps = vid.FrameRate;
H   = vid.Height;
W   = vid.Width;

% Input start and end time you want to analyze
vid_start = 8;
vid_end   = 18;

vid_start_frame = ceil(vid_start * fps);
vid_end_frame   = ceil(vid_end   * fps);
nFrames         = vid_end_frame - vid_start_frame + 1;

fprintf('  %d x %d,  %.2f fps,  %d frames  (%.2f s)\n', ...
        W, H, fps, nFrames, vid.Duration);

%% ── 2. Show first frame – user draws rectangle to pick gate region ───────
firstFrame = read(vid, vid_start_frame);

fig = figure('Name','Step 1 – Select gate region','NumberTitle','off');
imshow(firstFrame);
title({'Draw a rectangle over the gate region.' ...
       'Double-click inside the rectangle when done.'}, 'FontSize', 12);

rect = drawrectangle('InteractionsAllowed','all', 'Color','cyan', 'LineWidth', 2);

% Block until user double-clicks inside the ROI
addlistener(rect, 'ROIClicked', @(src,evt) onDoubleClick(evt));
uiwait(fig);

col_start = max(1, round(rect.Position(1)));
col_end   = min(W, round(rect.Position(1) + rect.Position(3)));
row_start = max(1, round(rect.Position(2)));
row_end   = min(H, round(rect.Position(2) + rect.Position(4)));

fprintf('Selected columns %d:%d,  rows %d:%d\n', col_start, col_end, row_start, row_end);

%% ── 2b. Pixel calibration – click two points 20 cm apart horizontally ───
% Reuse the same figure: update title and collect two clicks.
title({'Now click TWO points exactly 20 cm apart horizontally.' ...
       '(e.g. two ruler marks visible in the frame)' ...
       'Click point 1, then point 2.'}, 'FontSize', 12);

calib_pts     = ginput(2);                              % [x1 y1; x2 y2]
calib_px_dist = abs(calib_pts(2,1) - calib_pts(1,1));  % horizontal pixel distance
calib_real_cm = 20.0;
px_per_cm     = calib_px_dist / calib_real_cm;
cm_per_px     = calib_real_cm / calib_px_dist;

% Draw calibration overlay so user can verify, then close when ready
hold on;
line([calib_pts(1,1) calib_pts(2,1)], [calib_pts(1,2) calib_pts(2,2)], ...
     'Color','yellow', 'LineWidth', 2, 'LineStyle','--');
plot(calib_pts(:,1), calib_pts(:,2), 'yo', 'MarkerSize', 10, 'LineWidth', 2);
text(mean(calib_pts(:,1)), calib_pts(1,2)-15, ...
     sprintf('%.1f px = 20 cm\n(%.2f px/cm)', calib_px_dist, px_per_cm), ...
     'Color','yellow', 'FontSize', 10, 'FontWeight','bold', 'HorizontalAlignment','center');
title(sprintf('Calibration: %.1f px = 20 cm  |  %.3f cm/px  —  close this window to continue', ...
              calib_px_dist, cm_per_px), 'FontSize', 11, 'Color', [0.9 0.8 0]);
hold off;

fprintf('Calibration:  %.1f px = 20 cm  ->  %.3f cm/px  (%.2f px/cm)\n', ...
        calib_px_dist, cm_per_px, px_per_cm);

waitfor(fig);   % user closes figure to proceed

%% ── 3. Extract kymograph (space–time image) ──────────────────────────────
% For each frame: crop the selected strip, greyscale, average across columns
% → one brightness profile per frame. Stack → kymograph (rows=space, cols=time).

nRows = row_end - row_start + 1;
kymo  = zeros(nRows, nFrames);

fprintf('Building kymograph (%d frames)...\n', nFrames);

for f = vid_start_frame:vid_end_frame
    frame   = read(vid, f);
    gray    = im2gray(frame);
    strip   = gray(row_start:row_end, col_start:col_end);
    col_idx = f - vid_start_frame + 1;
    kymo(:, col_idx) = mean(strip, 2);
end
kymo = kymo / 255;   % normalise to [0,1]
fprintf('Done.\n');

%% ── 4. Preview kymograph and set edge search bounds interactively ────────
% Show the kymograph so the user can click to define the row range within
% which the gate edge travels, excluding spurious features (e.g. a bright
% strip at the bottom of the tank).

timeAxis_preview = (0:nFrames-1) / fps;

fig_kymo = figure('Name','Step 3 – Set search bounds','NumberTitle','off','Color','k');
imagesc(timeAxis_preview, 1:nRows, kymo);
colormap(inferno_cmap());
axis xy;
xlabel('Time (s)', 'Color','w');
ylabel('Row in strip (px)', 'Color','w');
title({'Click the TOP row limit, then the BOTTOM row limit' ...
       'of where the gate edge travels  (exclude bright tank-bottom strip).'}, ...
      'FontSize', 11, 'Color','w');
ax_p = gca; ax_p.XColor = 'w'; ax_p.YColor = 'w'; ax_p.Color = 'k';

[~, click_rows] = ginput(2);
search_row_start = max(1,     round(min(click_rows)));
search_row_end   = min(nRows, round(max(click_rows)));

hold on;
yline(search_row_start, 'c--', 'LineWidth', 1.5);
yline(search_row_end,   'c--', 'LineWidth', 1.5);
title(sprintf('Search rows %d – %d  |  close window to continue', ...
              search_row_start, search_row_end), ...
      'FontSize', 11, 'Color','c');
hold off;

fprintf('Edge search restricted to rows %d – %d\n', search_row_start, search_row_end);
waitfor(fig_kymo);

%% ── 4b. Detect gate edge position per frame (tracked) ───────────────────
% Rather than independently finding the best gradient peak each frame
% (which jumps between nuts and other features), we:
%   1. Find the edge in the first frame across the full search range.
%   2. In every subsequent frame, only search within +/- track_window rows
%      of the previous frame's result — the tracker cannot jump to a distant
%      nut or the tank-bottom strip.

track_window = round(nRows * 0.08);   % max rows the edge can move per frame
                                       % (~8% of strip height; increase if gate
                                       %  moves very fast relative to frame rate)

edgeRow = zeros(1, nFrames);

% Frame 1: search the full user-defined range to seed the tracker
edgeRow(1) = find_gradient_peak(kymo(:,1), search_row_start, search_row_end);

% Frames 2…end: search only within a window around the previous position
for f = 2:nFrames
    prev       = edgeRow(f-1);
    win_start  = max(search_row_start, prev - track_window);
    win_end    = min(search_row_end,   prev + track_window);
    edgeRow(f) = find_gradient_peak(kymo(:,f), win_start, win_end);
end

%% ── 5. Smooth and compute velocity ──────────────────────────────────────
smoothWin  = max(5, round(fps / 10));        % ~100 ms window
edgeSmooth = movmean(edgeRow, smoothWin);

dt        = 1 / fps;
velocity  = gradient(edgeSmooth * cm_per_px, dt);   % cm/s
velSmooth = movmean(velocity, smoothWin * 2);

% Position as displacement from the starting (closed) position
% edgeSmooth is in kymograph rows; convert to cm then zero at frame 1
edgeDisp_cm = (edgeSmooth - edgeSmooth(1)) * cm_per_px;   % cm, 0 at start, negative = gate lifting

%% ── 6. Find lift-off moment ──────────────────────────────────────────────
baseline  = median(edgeSmooth(1 : min(round(fps), nFrames)));
departure = abs(edgeSmooth - baseline);
liftIdx   = find(abs(edgeDisp_cm) > 0.5, 1, 'first');   % first frame >0.5 cm from rest
if isempty(liftIdx), liftIdx = 1; end

timeAxis     = (0:nFrames-1) / fps;
liftTime     = timeAxis(liftIdx);

[maxSpeed_cms, maxSpeedIdx] = min(velSmooth);   % most negative = fastest upward
maxSpeedTime = timeAxis(maxSpeedIdx);

fprintf('\n── Results ─────────────────────────────────────\n');
fprintf('  Calibration:           %.2f px/cm  (%.3f cm/px)\n', px_per_cm, cm_per_px);
fprintf('  Lift-off detected at:  %.3f s  (frame %d)\n', liftTime, liftIdx);
fprintf('  Peak lift speed:       %.2f cm/s  =  %.4f m/s\n', ...
        abs(maxSpeed_cms), abs(maxSpeed_cms)/100);
fprintf('  Total gate travel:     %.2f cm\n', max(-edgeDisp_cm));
fprintf('────────────────────────────────────────────────\n');

%% ── 7. Plots ─────────────────────────────────────────────────────────────

% --- Figure 1: Kymograph with detected edge ---
figure('Name','Kymograph','NumberTitle','off','Color','k');
imagesc(timeAxis, (1:nRows) * cm_per_px, kymo);
colormap(inferno_cmap());
axis xy;
hold on;
plot(timeAxis, edgeDisp_cm, 'c-', 'LineWidth', 1.2, 'DisplayName', 'raw edge');
plot(timeAxis, movmean(edgeDisp_cm, smoothWin), ...
     'w-', 'LineWidth', 2, 'DisplayName', 'smoothed edge');
xline(liftTime, 'y--', 'LineWidth', 1.5, 'DisplayName', 'lift-off');
xlabel('Time (s)', 'Color','w');
ylabel('Gate displacement from start (cm)', 'Color','w');
title('Kymograph – gate strip over time', 'Color','w');
legend('TextColor','w', 'Color','none', 'EdgeColor','w', 'Location','best');
ax = gca; ax.XColor = 'w'; ax.YColor = 'w'; ax.Color = 'k';
colorbar('Color','w');

% --- Figure 2: Gate position & velocity vs time ---
figure('Name','Gate position & velocity','NumberTitle','off');

subplot(2,1,1);
plot(timeAxis, -edgeDisp_cm, 'Color',[0.6 0.6 0.6], 'LineWidth', 0.8); hold on;
plot(timeAxis, -movmean(edgeDisp_cm, smoothWin), 'b-', 'LineWidth', 2);
xline(liftTime, 'r--', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Gate displacement (cm, upward +ve)');
title('Gate displacement from starting position');
legend('raw', 'smoothed', 'lift-off', 'Location','best');
grid on;

subplot(2,1,2);
plot(timeAxis, -velSmooth, 'r-', 'LineWidth', 2);
hold on;
xline(liftTime, 'r--', 'LineWidth', 1.5);
xline(maxSpeedTime, 'k:', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Lift speed (cm/s, upward +ve)');
title(sprintf('Gate lift speed  [peak: %.1f cm/s = %.4f m/s  at  t = %.3f s]', ...
              abs(maxSpeed_cms), abs(maxSpeed_cms)/100, maxSpeedTime));
grid on;

%% ── 8. Save results to CSV ───────────────────────────────────────────────
T = table(timeAxis', -edgeDisp_cm', -velSmooth', ...
          'VariableNames', {'Time_s', 'GateDisplacement_cm', 'LiftSpeed_cm_per_s'});
csvName = fullfile([exp_name '_gate_lift.csv']);
writetable(T, csvName);
fprintf('Results saved to: %s\n', csvName);

%% ── Helper: find steepest dark→bright transition in a row sub-range ─────
function row = find_gradient_peak(kymo_col, r_start, r_end)
    % Extract sub-profile, smooth, differentiate, return absolute row index
    % of the maximum positive gradient (dark-to-bright edge).
    profile    = kymo_col(r_start:r_end);
    profile_sm = movmean(profile, 5);
    dp         = gradient(profile_sm);
    [~, idx]   = max(dp);
    row        = idx + r_start - 1;
end

%% ── Helper: resume uiwait on double-click ────────────────────────────────
function onDoubleClick(evt)
    if strcmp(evt.SelectionType, 'double')
        uiresume(gcf);
    end
end

%% ── Helper: Inferno colormap ─────────────────────────────────────────────
function cmap = inferno_cmap()
    t = linspace(0,1,256)';
    r = clamp01(0.9879 .* t.^0.3 + 0.0121);
    g = clamp01(t.^1.5 .* (1 - 0.6.*t));
    b = clamp01(0.8 .* t.^4);
    cmap = [r, g, b];
end

function v = clamp01(x)
    v = max(0, min(1, x));
end