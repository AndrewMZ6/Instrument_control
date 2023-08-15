classdef DG
    % methods:
    %   DG.load_data(connectionID, chNum, amp)
    %   sets the amplitude value of the Trueform 33600A generator
    %
    %   WG.load_data(connectionID, data, chNum, fs, ArbFileName)
    %   upload data to generator and send it to chosen channel. Set sample
    %   frequency
    properties (Constant)
        M = containers.Map([25e6, 125e6], [7, 3]);
        
    end

    
    methods (Static)

        function s_string = stringify(data)
            s_string = '';

            for i = 1:length(data)
                s_string = [s_string, ',', num2str(data(i))];
            end
            
        end

        function instr_object = connect_visadev(connectionID)
            instr_object = visadev(connectionID);
            instr_object.Timeout = 10;
        end

        function load_data(connID, data, fs, amp)

            
            L = 16383;
            zeros_length = L - length(data);
            zeros_arr = zeros(1, zeros_length);
            singnal_with_zeros = [data, zeros_arr];
            
            % normalize if data abolute
            data_max = max(abs(singnal_with_zeros));

            if data_max > 1
                singnal_with_zeros = singnal_with_zeros/data_max;
            end


            s_string = DG.stringify(singnal_with_zeros);

            instr_object = DG.connect_visadev(connID);
            
            % Ask the instrument for it's name
            instr_name = writeread(instr_object, '*IDN?');
            disp(['dg -> connected to ', instr_name]);

            
            interp_value = writeread(instr_object, ':DATA:POIN:INT?');
            disp(['before load: ', interp_value]);
            
            write(instr_object, [':VOLTage ', num2str(amp)]);
            write(instr_object, ':FUNCtion:ARB:MODE PLAY');
            write(instr_object, [':FUNCtion:ARB:SAMPLE ', num2str(DG.M(fs))]);
%             write(instr_object, ':DATA:POIN:INT OFF');

            write(instr_object, [':DATA VOLATILE,', s_string]);
            write(instr_object, '*WAI');
%             write(instr_object, ':DATA:POIN:INT OFF');
            er = writeread(instr_object, 'SYST:ERR?');
            disp(['dg -> errors: ' , er]);
            write(instr_object, ':OUTPut ON');  


            pts = writeread(instr_object, ':DATA:POINts? VOLATILE');
            disp(['points? = ', num2str(pts)]);

        end

        function load_data_uint(connID, data)
            
            % normalize if data abolute
            data_max = max(abs(data));

            if data_max > 1
                data = data/data_max;
            end

            data = round(data, 4);
            L = num2str(length(data));
            L_string = num2str(length(L));

            
            s_string = DG.stringify(data);

            instr_object = DG.connect_visadev(connID);
            
            % Ask the instrument for it's name
            instr_name = writeread(instr_object, '*IDN?');
            disp(['dg -> connected to ', instr_name]);


            write(instr_object, ':DATA:POIN:INT OFF');
            interp_value = writeread(instr_object, ':DATA:POIN:INT?');
            disp(['before load: ', interp_value]);
            
            disp(s_string);
            
            command = [':DATA:DAC16 VOLATILE,END,', '#', L_string, L, s_string];
            disp(command);
            write(instr_object, command);


            interp_value = writeread(instr_object, ':DATA:POIN:INT?');
            disp(['after load: ', interp_value]);


            er = writeread(instr_object, 'SYST:ERR?');
            disp(['dg -> errors: ' , er]);


            write(instr_object, ':OUTPut ON');  

        end


    end
end