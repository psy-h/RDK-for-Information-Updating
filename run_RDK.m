function results = run_RDK(display, trial, coherence1, coherence2)
% run_RDK
% Run a random-dot kinematogram (RDK) task.
%
% Inputs:
%   trial.conditions   - Cell array of trial condition names
%   trial.n1        - Number of coherence1 trials for each condition
%   trial.n2       - Number of coherence2 trials for each condition
%   coherence1      - First coherence level
%   coherence2      - Second coherence level
%   display.viewDist   - Viewing distance in cm
%   display.screenWidth - Screen width in cm
%
% Output:
%   results - Struct array containing trial information:
%       .type         - Trial condition
%       .coherence    - Motion coherence
%       .motionDuration - Motion duration
%       .initDir      - Initial motion direction
%       .changeDir    - Final motion direction
%       .trueDir      - True final motion direction
%       .responseDir  - Participant's selected direction
%       .RT           - Response time

%%  RDK parameters

apertureDeg = 5;                     % Aperture diameter (degrees)
dotDensity = 16.7;                   % Dot density
dotSpeed = 6;                       % Dot speed (deg/s)
dotSize = 10;                       % Dot size (pixels)
dotLife = 3;                        % Dot lifetime (frames)

motionDirs = 0:22.5:337.5;           % Possible motion directions
changeAngle = 90;                    % Direction change for change trials


%% Open Psychtoolbox window

white = [255 255 255];
black = [0 0 0];
fixationColor = [200 0 0];
responseColor = [0 200 0];

[window, windowRect] = PsychImaging('OpenWindow', 0, white);

ifi = Screen('GetFlipInterval', window);
frameRate = 1 / ifi;

screenRes = windowRect(3);

pixPerCm = screenRes / display.screenWidth;
pixPerDeg = pixPerCm * tan(pi / 180) * display.viewDist;

apertureRadius = (apertureDeg / 2) * pixPerDeg;

[centerX, centerY] = RectCenter(windowRect);

HideCursor;


%% Calculate number of dots

dotsPerFrame = ceil( ...
    dotDensity * pi * (apertureDeg / 2)^2 / frameRate);

totalDots = dotsPerFrame * dotLife;

%% Generate trials

trials = struct( ...
    'type', {}, ...
    'coherence', {}, ...
    'motionDuration', {}, ...
    'initDir', {}, ...
    'changeDir', {}, ...
    'trueDir', {}, ...
    'responseDir', {}, ...
    'RT', {});

trialIndex = 0;

numDirs = length(motionDirs);

for c = 1:length(trial.conditions)

    condName = trial.conditions{c};

    n1 = trial.n1(c);
    n2 = trial.n2(c);

    if n1 > 0
        
        baseNum1 = floor(n1 / numDirs);

        remainder1 = mod(n1, numDirs);

        dirList1 = repmat( ...
            motionDirs, ...
            1, ...
            baseNum1);

        if remainder1 > 0

            extraIndex1 = ...
                randperm(numDirs, remainder1);

            extraDirs1 = ...
                motionDirs(extraIndex1);

            dirList1 = [ ...
                dirList1, ...
                extraDirs1];

        end

        dirList1 = ...
            dirList1(randperm(length(dirList1)));

    else

        dirList1 = [];

    end

    if n2 > 0

        baseNum2 = floor(n2 / numDirs);

        remainder2 = mod(n2, numDirs);

        dirList2 = repmat( ...
            motionDirs, ...
            1, ...
            baseNum2);

        if remainder2 > 0

            extraIndex2 = ...
                randperm(numDirs, remainder2);

            extraDirs2 = ...
                motionDirs(extraIndex2);

            dirList2 = [ ...
                dirList2, ...
                extraDirs2];

        end

        dirList2 = ...
            dirList2(randperm(length(dirList2)));

    else

        dirList2 = [];

    end
    
    coherenceList = [ ...
        repmat(coherence1, 1, n1), ...
        repmat(coherence2, 1, n2)];

    coherenceList = ...
        coherenceList(randperm(length(coherenceList)));

    count1 = 0;
    count2 = 0;

    for i = 1:length(coherenceList)

        trialIndex = trialIndex + 1;

        trials(trialIndex).type = ...
            condName;

        trials(trialIndex).coherence = ...
            coherenceList(i);

        if coherenceList(i) == coherence1

            count1 = count1 + 1;

            binDir = ...
                dirList1(count1);

        else

            count2 = count2 + 1;

            binDir = ...
                dirList2(count2);

        end

        trials(trialIndex).initDir = ...
            mod( ...
                binDir + ...
                (rand * 22.5 - 11.25), ...
                360);

        if strcmp(condName, 'change')

            trials(trialIndex).changeDir = ...
                mod( ...
                    trials(trialIndex).initDir ...
                    + sign(rand - 0.5) * changeAngle, ...
                    360);

        else

            trials(trialIndex).changeDir = ...
                trials(trialIndex).initDir;

        end

    end

end

trials = ...
    trials(randperm(length(trials)));

nTrials = length(trials);

%% Main experiment

Screen('TextFont', window, 'Times New Roman');
Screen('TextSize', window, 28);

instructionText = [ ...
    'Welcome to the task!\n\n' ...
    'You will see black dots moving inside a circular area.\n\n' ...
    'After the motion stops, a green dot will appear.\n\n' ...
    'Use the mouse to adjust the direction line so that it matches\n' ...
    'the final motion direction you saw, then click the left mouse button to confirm your response.\n\n' ...
    'Press SPACE to begin.'];

DrawFormattedText( ...
    window, ...
    instructionText, ...
    'center', ...
    'center', ...
    black);

Screen('Flip', window);

while true

    [keyDown, ~, keyCode] = KbCheck;

    if keyDown && keyCode(KbName('SPACE'))
        break;
    end
end

while KbCheck
end

for t = 1:nTrials

    Screen('FillRect', window, white);

    Screen('FillOval', ...
        window, ...
        fixationColor, ...
        [ ...
        centerX - 5, ...
        centerY - 5, ...
        centerX + 5, ...
        centerY + 5]);
    
    Screen( ...
        'FrameOval', ...
        window, ...
        black, ...
        [ ...
        centerX - apertureRadius, ...
        centerY - apertureRadius, ...
        centerX + apertureRadius, ...
        centerY + apertureRadius], ...
        4);
    
    Screen('Flip', window);

    WaitSecs(0.5);

    theta = 2 * pi * rand(1, totalDots);

    radius = ...
        apertureRadius * sqrt(rand(1, totalDots));

    dotPos = ...
        [cos(theta); sin(theta)] .* radius;

    dotLifeTracker = ...
        repmat(1:dotLife, 1, dotsPerFrame);

    dirRadInit = ...
        deg2rad(trials(t).initDir);

    dirRadChange = ...
        deg2rad(trials(t).changeDir);

    dotStep = dotSpeed * pixPerDeg * dotLife / frameRate;

    motionInit = [cos(dirRadInit); sin(dirRadInit)] * dotStep;

    motionChange = [cos(dirRadChange); sin(dirRadChange)] * dotStep;

    if strcmp(trials(t).type, 'noChangeShort')

        duration = 0.5;

    else

        duration = 1.0;

    end

    numFrames = round(duration * frameRate);

    for frame = 1:numFrames

        currentSet = ...
            mod(frame - 1, dotLife) + 1;

        idx = find(dotLifeTracker == currentSet);

        motionVec = motionInit;

        if strcmp(trials(t).type, 'change') ...
                && frame > numFrames / 2

            motionVec = motionChange;

        end

        Screen('FillRect', window, white);
        
        Screen( ...
            'DrawDots', ...
            window, ...
            dotPos(:, idx) + [centerX; centerY], ...
            dotSize, ...
            black, ...
            [], ...
            2);

        Screen( ...
            'FrameOval', ...
            window, ...
            black, ...
            [ ...
            centerX - apertureRadius, ...
            centerY - apertureRadius, ...
            centerX + apertureRadius, ...
            centerY + apertureRadius], ...
            4);


        Screen('Flip', window);
        
        for iDot = idx

            if rand < trials(t).coherence

                dotPos(:, iDot) = ...
                    dotPos(:, iDot) + motionVec;

            else

                angleRand = rand * 2 * pi;

                rRand = ...
                    apertureRadius * sqrt(rand);

                dotPos(:, iDot) = ...
                    [cos(angleRand); sin(angleRand)] * rRand;

            end

            if norm(dotPos(:, iDot)) > apertureRadius

                angleReset = rand * 2 * pi;
                               
                dotPos(:, iDot) = ...
                    [cos(angleReset); sin(angleReset)] ...
                    * apertureRadius;

            end

        end

    end

    Screen('FillRect', window, white);

    Screen('FillOval', ...
        window, ...
        responseColor, ...
        [ ...
        centerX - 5, ...
        centerY - 5, ...
        centerX + 5, ...
        centerY + 5]);

    Screen( ...
        'FrameOval', ...
        window, ...
        black, ...
        [ ...
        centerX - apertureRadius, ...
        centerY - apertureRadius, ...
        centerX + apertureRadius, ...
        centerY + apertureRadius], ...
        4);

    Screen('Flip', window);

    responseStartTime = GetSecs;

    SetMouse(centerX, centerY, window);

    mouseMoved = false;
    responseGiven = false;

    while ~responseGiven

        [x, y, buttons] = GetMouse(window);

        if x ~= centerX || y ~= centerY
            mouseMoved = true;
        end

        if mouseMoved

            angle = ...
                atan2(y - centerY, x - centerX);

            endX = ...
                centerX + cos(angle) * apertureRadius;

            endY = ...
                centerY + sin(angle) * apertureRadius;

            Screen('FillRect', window, white);

            Screen('FillOval', ...
                window, ...
                responseColor, ...
                [ ...
                centerX - 5, ...
                centerY - 5, ...
                centerX + 5, ...
                centerY + 5]);

            Screen('DrawLine', ...
                window, ...
                responseColor, ...
                centerX, ...
                centerY, ...
                endX, ...
                endY, ...
                4);

            Screen('FillOval', ...
                window, ...
                responseColor, ...
                [ ...
                endX - 6, ...
                endY - 6, ...
                endX + 6, ...
                endY + 6]);

            Screen( ...
                'FrameOval', ...
                window, ...
                black, ...
                [ ...
                centerX - apertureRadius, ...
                centerY - apertureRadius, ...
                centerX + apertureRadius, ...
                centerY + apertureRadius], ...
                4);

            Screen('Flip', window);

        end

        if mouseMoved && any(buttons)

            responseGiven = true;
            responseEndTime = GetSecs;
            
        end

    end
    
    RT = responseEndTime - responseStartTime;

    responseDir = ...
        mod(rad2deg(angle), 360);

    trueDir = ...
        trials(t).changeDir;

    trials(t).trueDir = trueDir;

    trials(t).responseDir = responseDir;

    trials(t).RT = RT;
    
    trials(t).motionDuration = duration;

    Screen('FillRect', window, white);
    Screen('Flip', window);
    WaitSecs(1.0);
    
end

ShowCursor;

sca;

results = trials;

end