classdef MSO
    % methods:
    %   MSO.channel_amp(connectionID, chNum, amp)
    %   sets the amplitude value of the Trueform 33600A generator
    %
    %   WG.load_data(connectionID, data, chNum, fs, ArbFileName)
    %   upload data to generator and send it to chosen channel. Set sample
    %   frequency
    
    
    methods (Static)
        function instr_object = connect_visadev(connectionID)
            instr_object = visadev(connectionID);
            instr_object.Timeout = 10;
        end

        function preambula_struct = create_pre_struct(pre)
            
            % preambula is acquired in form of csv (comma separated values)
            % so first of all split the values by ','
            split_pre = split(pre, ',');

            preambula_struct.format.value = str2num(split_pre(1));
            preambula_struct.format.description = '<format>: indicates 0 (BYTE), 1 (WORD), or 2 (ASC).';

            preambula_struct.type.value = str2num(split_pre(2));
            preambula_struct.type.description = '<type>: indicates 0 (NORMal), 1 (MAXimum), or 2 (RAW).';

            preambula_struct.points.value = str2num(split_pre(3));
            preambula_struct.points.description = '<points>: After the memory depth option is installed, <points> is an integer ranging from 1 to 200,000,000.';

            preambula_struct.count.value = str2num(split_pre(4));
            preambula_struct.count.description = '<count>: indicates the number of averages in the average sample mode. The value of <count> parameter is 1 in other modes.';

            preambula_struct.xincrement.value = str2num(split_pre(5));
            preambula_struct.xincrement.description = '<xincrement>: indicates the time difference between two neighboring points in the X direction.';

            preambula_struct.xorigin.value = str2num(split_pre(6));
            preambula_struct.xorigin.description = '<xorigin>: indicates the start time of the waveform data in the X direction.';

            preambula_struct.xreference.value = str2num(split_pre(7));
            preambula_struct.xreference.description = '<xreference>: indicates the reference time of the waveform data in the X direction.';

            preambula_struct.yincrement.value = str2num(split_pre(8));
            preambula_struct.yincrement.description = '<yincrement>: indicates the step value of the waveforms in the Y direction.';

            preambula_struct.yorigin.value = str2num(split_pre(9));
            preambula_struct.yorigin.description = '<yorigin>: indicates the vertical offset relative to the "Vertical Reference Position" in the Y direction.';

            preambula_struct.yreference.value = str2num(split_pre(10));
            preambula_struct.yreference.description = '<yreference>: indicates the vertical reference position in the Y direction.';


        end
        
        function [processed_data, preambula_struct] = process_acquired_data(data, pre)
            
            preambula_struct = MSO.create_pre_struct(pre);

            if (preambula_struct.points.value ~= length(data))
                error('mso -> Read error: preambula.points != length(data)');
            end
            

            yincrement = preambula_struct.yincrement.value;
            yref = preambula_struct.yreference.value;

            % create container for processed data
            processed_data = zeros(1, length(data));

            % find values that are considered positive or negative in
            % regards to reference value "yref"
            ypositive_indexes = find(data > yref);
            ynegative_indexes = find(data < yref);
            
            % make positive and negative data actual
            positive_data = (data(ypositive_indexes) - yref)*yincrement;
            negative_data = (data(ynegative_indexes) - yref)*yincrement;
            
            % place the data in container
            processed_data(ypositive_indexes) = positive_data;
            processed_data(ynegative_indexes) = negative_data;

        end

        function [revived_sig, preambula] = read_data_normal(connectionID, ch_num)

            % connect to the instrument
            instr_object = MSO.connect_visadev(connectionID);
            
            instr_name = writeread(instr_object, '*IDN?');
            disp(['mso -> connected to ', instr_name]);
            
            read_success_flag = 0;

            while ~read_success_flag
            
                try
                    % set the acquirance regime
                    write(instr_object, ':STOP');
                    write(instr_object, [':WAV:SOUR CHAN', num2str(ch_num)]);
        
                    write(instr_object, ':WAV:MODE NORMal');
                    write(instr_object, ':WAV:FORM BYTE');
                    
                    % acquire preambula
                    pre = writeread(instr_object, ':WAV:PRE?');
                   
                    % acquire data
                    write(instr_object, ':WAV:DATA?');
                    write(instr_object, '*WAI');
                    data = readbinblock(instr_object, 'uint8');
                    
                    % check for system errors
                    errs = writeread(instr_object, ':SYST:ERR?');
                    write(instr_object, ':RUN');
                    
                    disp(['mso -> errors: ' , errs]);
                    
        
                    [revived_sig, preambula] = MSO.process_acquired_data(data, pre);

                    read_success_flag = 1;
                catch err

                    disp(['catched error read_data_normal: ', err.message]);

                end

            end


        end


        function [revived_sig, preambula] = read_data_raw(connectionID, ch_num, points)


            % connect to the instrument
            instr_object = MSO.connect_visadev(connectionID);
            
            instr_name = writeread(instr_object, '*IDN?');
            disp(['mso -> connected to ', instr_name]);


            read_success_flag = 0;

            while ~read_success_flag
            
                try
            
                    % set the acquirance regime
                    write(instr_object, ':STOP');
                    write(instr_object, [':WAV:SOUR CHAN', num2str(ch_num)]);
        
                    write(instr_object, ':WAV:MODE RAW');
                    write(instr_object, ':WAV:FORM BYTE');
                    write(instr_object, [':WAV:POINts ', num2str(points)]);
                    
                    % acquire preambula
                    pre = writeread(instr_object, ':WAV:PRE?');
                    
                    % acquire data
                    write(instr_object, ':WAV:DATA?');
                    write(instr_object, '*WAI');
                    data = readbinblock(instr_object, 'uint8');
                    
                    % check for system errors
                    errs = writeread(instr_object, ':SYST:ERR?');
                    write(instr_object, ':RUN');
                    
                    disp(['mso -> errors: ' , errs]);
                    
                    [revived_sig, preambula] = MSO.process_acquired_data(data, pre);
                    read_success_flag = 1;

                catch err

                    disp(['catched error read_data_raw: ', err.message]);

                end

            end


        end

        function [revived_sig, preambula] = read_data_max(connectionID, ch_num)

            
            
            % connect to the instrument
            instr_object = MSO.connect_visadev(connectionID);
            
            instr_name = writeread(instr_object, '*IDN?');
            disp(['mso -> connected to ', instr_name]);


            read_success_flag = 0;

            while ~read_success_flag
            
                try
            
                    % set the acquirance regime
                    write(instr_object, ':STOP');
                    write(instr_object, [':WAV:SOUR CHAN', num2str(ch_num)]);
        
                    write(instr_object, ':WAV:MODE MAX');
                    write(instr_object, ':WAV:FORM BYTE');
                    
                    % acquire preambula
                    pre = writeread(instr_object, ':WAV:PRE?');
                    
                    % acquire data
                    write(instr_object, ':WAV:DATA?');
                    write(instr_object, '*WAI');
                    data = readbinblock(instr_object, 'uint8');
        
                    
                    % check for system errors
                    errs = writeread(instr_object, ':SYST:ERR?');
                    write(instr_object, ':RUN');
                    
                    % display system errors
                    disp(['mso -> errors: ' , errs]);
                    
                    [revived_sig, preambula] = MSO.process_acquired_data(data, pre);

                    read_success_flag = 1;

                catch err

                    disp(['catched error in read_data_max: ', err.message]);

                end

            end


        end

    end
end