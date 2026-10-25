clc, clear, format long g

% Read file
raster_plynuly = imread('Image1_plynuly_prechod.bmp');
raster_ostry = imread('Image2_ostre_prechody_mapa.bmp');
raster_fotka = imread('Image3_fotografie.bmp');
raster_cernobile = imread('Image4_odstiny_sedi.bmp');

% Run the compression test
compression_test(raster_fotka,100,'none','dct')


function compression_test(raster, q, resample_type, transform_type)
% JPEG compression setup evaluation.
%
% raster - input RGB image
% 
% q - compression factor used to scale the quantization matrices 
%  - Possible values:
%      from 0 to 100
% 
% resample_type - submatrix resampling method
%  - Possible values:
%      'none' - no resampling
%      '2x1'  - 2x1 block averaging
%      '2x2'  - 2x2 block averaging
%      '3x3'  - 3x3 block averaging
%      '4x4'  - 4x4 block averaging
%
% transform_type - transformation method for compression
%   - Possible values:
%      'dct'  - Discrete Cosine Transform
%      'dft'  - Discrete Fourier Transform
%      'dwt'  - Discrete Wavelet Transform (Haar Wavelet)

    % Extract components
    R = double(raster(:, :, 1));
    G = double(raster(:, :, 2));
    B = double(raster(:, :, 3));
    [m, n] = size(R);

    % Conversion RGB to YCbCr
    Y  =  0.299  * R + 0.587  * G + 0.114  * B;
    Cb = -0.1687 * R - 0.3313 * G + 0.5    * B + 128;
    Cr =  0.5    * R - 0.4187 * G - 0.0813 * B + 128;

    % Interval transformation
    Y  = 2*Y  - 255;
    Cb = 2*Cb - 255;
    Cr = 2*Cr - 255;

    % Quantisation matrix: Y
    QY_base = [16 11 10 16 24 40 51 61;
               12 12 14 19 26 58 60 55;
               14 13 16 24 40 87 69 56;
               14 17 22 29 51 87 80 62;
               18 22 37 26 68 109 103 77;
               24 35 55 64 81 104 113 92;
               49 64 78 87 103 121 120 101;
               72 92 95 98 112 100 103 99];
           
    % Quantisation matrix: Cb, Cr
    QC_base = [17 18 24 47 66 99 99 99;
               18 21 26 66 99 99 99 99;
               24 26 56 99 99 99 99 99;
               47 69 99 99 99 99 99 99;
               99 99 99 99 99 99 99 99;
               99 99 99 99 99 99 99 99;
               99 99 99 99 99 99 99 99;
               99 99 99 99 99 99 99 99];

    % Scale quantization matrices by quality factor q
    if q <= 0
        q = 1;
    end
    QY = (50 * QY_base) / q;
    QC = (50 * QC_base) / q;

    % Apply transform
    is_dft = false;
    tf_name = lower(transform_type);

    if strcmp(resample_type, 'none')
        resample_type_num = 0;
    elseif strcmp(resample_type, '2x1')
        resample_type_num = 1;
    elseif strcmp(resample_type, '2x2')
        resample_type_num = 2;
    elseif strcmp(resample_type, '3x3')
        resample_type_num = 3;
    elseif strcmp(resample_type, '4x4')
        resample_type_num = 4;
    else
        error('Unknown resample_type. Use ''none'', ''2x1'', ''2x2'', ''3x3'', or ''4x4''.');
    end
    
    if strcmp(tf_name, 'dct')
        Y_t  = mydct(Y,  QY, resample_type_num);
        Cb_t = mydct(Cb, QC, resample_type_num);
        Cr_t = mydct(Cr, QC, resample_type_num);
        
        Y_2  = myidct(Y_t,  QY, m, n);
        Cb_2 = myidct(Cb_t, QC, m, n);
        Cr_2 = myidct(Cr_t, QC, m, n);
        
    elseif strcmp(tf_name, 'dft')
        Y_t  = mydft(Y,  QY, resample_type_num);
        Cb_t = mydft(Cb, QC, resample_type_num);
        Cr_t = mydft(Cr, QC, resample_type_num);
        
        Y_2  = myidft(Y_t,  QY, m, n);
        Cb_2 = myidft(Cb_t, QC, m, n);
        Cr_2 = myidft(Cr_t, QC, m, n);
        is_dft = true;
        
    elseif strcmp(tf_name, 'dwt')
        Y_t  = mydwt(Y,  QY, resample_type_num);
        Cb_t = mydwt(Cb, QC, resample_type_num);
        Cr_t = mydwt(Cr, QC, resample_type_num);
        
        Y_2  = myidwt(Y_t,  QY, m, n);
        Cb_2 = myidwt(Cb_t, QC, m, n);
        Cr_2 = myidwt(Cr_t, QC, m, n);
        
    else
        error('Unknown transform_type. Use ''dct'', ''dft'', or ''dwt''.');
    end

    % Interval back-transformation
    Y_2  = 0.5 * (Y_2  + 255);
    Cb_2 = 0.5 * (Cb_2 + 255);
    Cr_2 = 0.5 * (Cr_2 + 255);

    % Conversion YCbCr to RGB
    R2 = Y_2 + 1.4020 * (Cr_2 - 128);
    G2 = Y_2 - 0.3441 * (Cb_2 - 128) - 0.7141 * (Cr_2 - 128);
    B2 = Y_2 + 1.7720 * (Cb_2 - 128);

    % Assemble raster (uint8 clamps values to 0..255)
    raster2 = uint8(cat(3, R2, G2, B2));

    % Show original and compressed image
    figure;
    subplot(1, 2, 1), imshow(raster), title('Original')
    subplot(1, 2, 2), imshow(raster2), title(sprintf('%s, q = %d, resampling: %s', upper(transform_type), q, resample_type))

    % Root mean square error computation
    R_error = error(R, R2);
    G_error = error(G, G2);
    B_error = error(B, B2);

    %% Size & Compression Comparison calculation - GENERATED STRICTLY USING AI
    original_bytes = numel(raster);
    compressed_bits = 0;
    components = {Y_t, Cb_t, Cr_t};

    for c = 1:length(components)
        comp_cell = components{c};
        for b = 1:length(comp_cell)
            if is_dft
                % DFT includes both real and imaginary bitstreams & dictionaries
                compressed_bits = compressed_bits + length(comp_cell{b}.real_enc.code);
                compressed_bits = compressed_bits + length(comp_cell{b}.imag_enc.code);
                
                dict_real = comp_cell{b}.real_enc.dict;
                for d = 1:size(dict_real, 1)
                    compressed_bits = compressed_bits + 16 + 8 + length(dict_real{d, 2});
                end
                
                dict_imag = comp_cell{b}.imag_enc.dict;
                for d = 1:size(dict_imag, 1)
                    compressed_bits = compressed_bits + 16 + 8 + length(dict_imag{d, 2});
                end
            else
                % DCT / DWT single stream
                compressed_bits = compressed_bits + length(comp_cell{b}.code);
                dict = comp_cell{b}.dict;
                for d = 1:size(dict, 1)
                    compressed_bits = compressed_bits + 16 + 8 + length(dict{d, 2});
                end
            end
        end
    end

    compressed_bytes = compressed_bits / 8;
    compression_ratio = original_bytes / compressed_bytes;
    space_saving = (1 - (compressed_bytes / original_bytes)) * 100;

    % Print all metrics directly to the command window
    fprintf('-----------------------------------------\n');
    fprintf('Transform Type:            %s\n', upper(transform_type));
    fprintf('Quality Factor (q):        %d\n', q);
    fprintf('Resampling Mode:           %s\n', resample_type);
    fprintf('Original Image Size:       %.2f KB (%d bytes)\n', original_bytes / 1024, original_bytes);
    fprintf('Compressed Size (w/ Dict): %.2f KB (%.0f bits)\n', compressed_bytes / 1024, compressed_bits);
    fprintf('Compression Ratio:         %.2f : 1\n', compression_ratio);
    fprintf('Space Saving:              %.2f%%\n', space_saving);
    fprintf('RMSE R Channel:            %.4f\n', R_error);
    fprintf('RMSE G Channel:            %.4f\n', G_error);
    fprintf('RMSE B Channel:            %.4f\n', B_error);
    fprintf('-----------------------------------------\n');
end


%% ---------------- Local functions ----------------

function [Rt] = mydct(R, Q, resample_type)
% DCT + quantisation of entire raster + raster resampling
% + Zig-Zag sequence + Huffman encoding
    [m, n] = size(R);
    Rt = {};
    idx = 1;
    for i = 1:8:m-7
        for j = 1:8:n-7

            % Separate 8x8 submatrix
            R_sub = R(i:i+7, j:j+7);

            % Raster resampling
            R_sub = resample_submatrix(R_sub, resample_type);

            % Apply DCT
            R_sub_dct = mydctsub(R_sub);

            % Quantization
            R_quant = round(R_sub_dct ./ Q);

            % Zig-Zag sequence
            R_zz = zigzag(R_quant);
            
            % Huffman encoding
            Rt{idx} = huffman_encode_block(R_zz);
            idx = idx + 1;
        end
    end
end


function [Rt] = myidct(R, Q, m, n)
% Dequantisation + inverse DCT of entire raster
    Rt = zeros(m, n);
    idx = 1;
    for i = 1:8:m-7
        for j = 1:8:n-7
            % Retrieve the encoded block from the cell array
            R_sub = R{idx};
            idx = idx + 1;

            % Huffman decoding 
            R_zz_vec = huffman_decode_block(R_sub);

            % Apply reverse Zig-Zag
            R_izz = izigzag(R_zz_vec);

            % Dequantisation
            R_sub_dequant = R_izz .* Q;

            % Inverse DCT
            Rt(i:i+7, j:j+7) = myidctsub(R_sub_dequant);
        end
    end
end


function [Rt] = mydctsub(R)
% Forward DCT of 8 x 8 matrix
    Rt = zeros(8);
    for u = 0:7
        if u == 0, cu = sqrt(2)/2; else, cu = 1; end
        for v = 0:7
            if v == 0, cv = sqrt(2)/2; else, cv = 1; end
            s = 0;
            for x = 0:7
                for y = 0:7
                    s = s + R(x+1, y+1) * cos((2*x+1)*u*pi/16) * cos((2*y+1)*v*pi/16);
                end
            end
            Rt(u+1, v+1) = 1/4 * cu * cv * s;
        end
    end
end


function [Rt] = myidctsub(R)
% Inverse DCT of 8 x 8 matrix, formula (15)
    Rt = zeros(8);
    for x = 0:7
        for y = 0:7
            s = 0;
            for u = 0:7
                if u == 0, cu = sqrt(2)/2; else, cu = 1; end
                for v = 0:7
                    if v == 0, cv = sqrt(2)/2; else, cv = 1; end
                    s = s + cu * cv * R(u+1, v+1) * cos((2*x+1)*u*pi/16) * cos((2*y+1)*v*pi/16);
                end
            end
            Rt(x+1, y+1) = s / 4;
        end
    end
end


function [E] = error(C1, C2)
    [m, n] = size(C1);

    diff_c = C2 - C1;
    E = sqrt(sum(sum(diff_c.^2))/(m*n));

end


function [R_resampled] = resample_submatrix(R_sub, type)
% Resamples an 8x8 submatrix:
% 0 = none, 1 = 2x1, 2 = 2x2, 3 = 3x3, 4 = 4x4
    R_resampled = R_sub;
    if type == 0
        return;
    end
    
    % Define block dimensions
    if type == 1
        bh = 2; bw = 1;
    elseif type == 2
        bh = 2; bw = 2;
    elseif type == 3
        bh = 3; bw = 3;
    elseif type == 4
        bh = 4; bw = 4;
    else
        return;
    end
    
    [nrows, ncols] = size(R_sub);
    
    % Loop through blocks
    for i = 1:bh:nrows
        for j = 1:bw:ncols
            i_end = min(i + bh - 1, nrows);
            j_end = min(j + bw - 1, ncols);
            
            % Compute average of the block
            block_sum = 0;
            count = 0;
            for r = i:i_end
                for c = j:j_end
                    block_sum = block_sum + R_sub(r, c);
                    count = count + 1;
                end
            end
            block_avg = block_sum / count;
            
            % Assign the average back to the block
            for r = i:i_end
                for c = j:j_end
                    R_resampled(r, c) = block_avg;
                end
            end
        end
    end
end


function [zz_vec] = zigzag(block)
% Converts an 8x8 block into zig-zag sequence
    order = [
        1  2  6  7 15 16 28 29;
        3  5  8 14 17 27 30 43;
        4  9 13 18 26 31 42 44;
        10 12 19 25 32 41 45 54;
        11 20 24 33 40 46 53 55;
        21 23 34 39 47 52 56 61;
        22 35 38 48 51 57 60 62;
        36 37 49 50 58 59 63 64
        ];
    zz_vec = zeros(1, 64);
    for i = 1:8
        for j = 1:8
            zz_vec(order(i, j)) = block(i, j);
        end
    end
end


function [block] = izigzag(zz_vec)
% Reconstructs the 8x8 block from zig-zag sequence
    order = [
        1  2  6  7 15 16 28 29;
        3  5  8 14 17 27 30 43;
        4  9 13 18 26 31 42 44;
        10 12 19 25 32 41 45 54;
        11 20 24 33 40 46 53 55;
        21 23 34 39 47 52 56 61;
        22 35 38 48 51 57 60 62;
        36 37 49 50 58 59 63 64
        ];
    block = zeros(8, 8);
    for i = 1:8
        for j = 1:8
            block(i, j) = zz_vec(order(i, j));
        end
    end
end


function dict = my_huffmandict(symbols, probabilities)
% Generates a Huffman dictionary
    n = length(symbols);
    if n == 1
        dict = {symbols(1), '0'};
        return;
    end
    
    % Create initial nodes as a cell array of structs
    nodes = cell(n, 1);
    for i = 1:n
        nodes{i} = struct('prob', probabilities(i), 'symbol', symbols(i), 'left', [], 'right', []);
    end
    
    % Build Huffman tree
    while length(nodes) > 1
        % Extract probabilities
        num_nodes = length(nodes);
        probs = zeros(1, num_nodes);
        for k = 1:num_nodes
            probs(k) = nodes{k}.prob;
        end
    
        % Sort nodes by probability in ascending order
        [~, idx] = sort(probs);
        nodes = nodes(idx);
    
        % Take the two lowest probability nodes
        left = nodes{1};
        right = nodes{2};
    
        % Create a parent node combining their probabilities
        parent = struct('prob', left.prob + right.prob, 'symbol', [], 'left', left, 'right', right);
    
        % Remove the two nodes and add the parent node
        nodes(1:2) = [];
        nodes{end+1} = parent;
    end
    
    root = nodes{1};
    dict = {};
    dict = generate_codes(root, '', dict);
end


function dict = generate_codes(node, code, dict)
% Recursively traverses the Huffman tree to assign binary codes
    if ~isempty(node.symbol)
        dict = [dict; {node.symbol, code}];
    else
        if ~isempty(node.left)
            dict = generate_codes(node.left, [code '0'], dict);
        end
        if ~isempty(node.right)
            dict = generate_codes(node.right, [code '1'], dict);
        end
    end
end


function encoded = my_huffmanenco(seq, dict)
% Encodes a sequence of symbols into a binary bit vector
    encoded_str = '';
    for i = 1:length(seq)
        sym = seq(i);
        for j = 1:size(dict, 1)
            if dict{j, 1} == sym
                encoded_str = [encoded_str, dict{j, 2}];
                break;
            end
        end
    end
    % Convert binary string into a numeric vector
    encoded = double(encoded_str) - '0';
end


function decoded = my_huffmandec(encoded, dict)
% Decodes a binary bit vector back into the original symbol sequence
    encoded_str = char(encoded + '0');
    decoded = [];
    current_code = '';
    
    for i = 1:length(encoded_str)
        current_code = [current_code, encoded_str(i)];
    
        % Check if the current bit combination matches any dictionary code
        for j = 1:size(dict, 1)
            if strcmp(dict{j, 2}, current_code)
                decoded(end+1) = dict{j, 1};
                current_code = '';
                break;
            end
        end
    end
end


function enc_block = huffman_encode_block(R_zz)
% Encodes a single 8x8 block using the custom Huffman coding
    [symbols, ~, ic] = unique(R_zz);
    counts = histcounts(ic, 1:(length(symbols)+1));
    probabilities = counts / sum(counts);
    
    dict = my_huffmandict(symbols, probabilities);
    encoded_block = my_huffmanenco(R_zz, dict);
    
    enc_block.code = encoded_block;
    enc_block.dict = dict;
end


function R_zz_vec = huffman_decode_block(enc_block)
% Decodes a single 8x8 block using the custom Huffman coding
    R_zz_vec = my_huffmandec(enc_block.code, enc_block.dict);
    
    % Ensure the decoded vector matches the standard 64-element size
    if length(R_zz_vec) < 64
        R_zz_vec(end+1:64) = 0;
    end
end


function [Rt_cell] = mydft(R, Q_scaled, resample_type)
% DFT + 2D Frequency Reordering + Standard Quantization + Zig-Zag + Huffman
    [m, n] = size(R);
    
    % Permutation vector to bring DFT low frequencies to top-left
    poradi = [1 2 8 3 7 4 6 5];
    
    Rt_cell = {};
    idx = 1;
    for i = 1:8:m-7
        for j = 1:8:n-7
            % 1. Separate 8x8 submatrix & resample
            R_sub = R(i:i+7, j:j+7);
            R_sub = resample_submatrix(R_sub, resample_type);
            
            % 2. Apply 2D DFT
            R_sub_dft = mydftsub(R_sub);
            
            % 3. Separate Real and Imaginary parts
            R_real = real(R_sub_dft);
            R_imag = imag(R_sub_dft);
            
            % 4. Arrange matrix elements so low frequencies are at top-left
            R_real_sorted = R_real(poradi, poradi);
            R_imag_sorted = R_imag(poradi, poradi);
            
            % 5. Quantize using quantization matrix
            R_quant_real = round(R_real_sorted ./ Q_scaled);
            R_quant_imag = round(R_imag_sorted ./ Q_scaled);
            
            % 6. Standard Zig-Zag sequence
            R_zz_real = zigzag(R_quant_real);
            R_zz_imag = zigzag(R_quant_imag);
            
            % 7. Huffman encode both streams into block structure
            block_struct.real_enc = huffman_encode_block(R_zz_real);
            block_struct.imag_enc = huffman_encode_block(R_zz_imag);
            
            Rt_cell{idx} = block_struct;
            idx = idx + 1;
        end
    end
end


function [Rt] = myidft(Rt_cell, Q_scaled, m, n)
% Huffman decoding + Inverse Zig-Zag + Dequantization + Inverse Reordering + IDFT
    Rt = zeros(m, n);
    
    poradi = [1 2 8 3 7 4 6 5];
    inv_poradi = zeros(1, 8);
    for k = 1:8
        inv_poradi(poradi(k)) = k;
    end
    
    idx = 1;
    for i = 1:8:m-7
        for j = 1:8:n-7
            % 1. Retrieve and decode block
            block_struct = Rt_cell{idx};
            idx = idx + 1;
            
            R_zz_real = huffman_decode_block(block_struct.real_enc);
            R_zz_imag = huffman_decode_block(block_struct.imag_enc);
            
            % 2. Inverse Zig-Zag
            R_izz_real = izigzag(R_zz_real);
            R_izz_imag = izigzag(R_zz_imag);
            
            % 3. Dequantization
            R_dequant_real = R_izz_real .* Q_scaled;
            R_dequant_imag = R_izz_imag .* Q_scaled;
            
            % 4. Revert the permutation back to uncentered DFT layout
            R_real_unsorted = R_dequant_real(inv_poradi, inv_poradi);
            R_imag_unsorted = R_dequant_imag(inv_poradi, inv_poradi);
            
            % 5. Reconstruct complex frequency block
            F = R_real_unsorted + 1j * R_imag_unsorted;
            
            % 6. Inverse DFT (taking real part to clear residual numerical noise)
            Rt(i:i+7, j:j+7) = real(myidftsub(F));
        end
    end
end


function [Rt] = mydftsub(R)
% Forward 2D DFT of an 8x8 matrix
    N = 8;
    Rt = zeros(N, N);
    for u = 0:N-1
        for v = 0:N-1
            s = 0;
            for x = 0:N-1
                for y = 0:N-1
                    angle = -2 * pi * (u * x + v * y) / N;
                    s = s + R(x+1, y+1) * exp(1j * angle);
                end
            end
            Rt(u+1, v+1) = s;
        end
    end
end


function [Rt] = myidftsub(R)
% Inverse 2D DFT of an 8x8 matrix
    N = 8;
    Rt = zeros(N, N);
    for x = 0:N-1
        for y = 0:N-1
            s = 0;
            for u = 0:N-1
                for v = 0:N-1
                    angle = 2 * pi * (u * x + v * y) / N;
                    s = s + R(u+1, v+1) * exp(1j * angle);
                end
            end
            Rt(x+1, y+1) = s / (N * N);
        end
    end
end


function [Rt_cell] = mydwt(R, Q_scaled, resample_type)
% DWT + Standard Quantization + Zig-Zag + Huffman encoding
    [m, n] = size(R);
    Rt_cell = {};
    idx = 1;
    
    for i = 1:8:m-7
        for j = 1:8:n-7
            % 1. Separate 8x8 submatrix & resample
            R_sub = R(i:i+7, j:j+7);
            R_sub = resample_submatrix(R_sub, resample_type);
            
            % 2. Apply 2D Haar Wavelet Transform
            R_dwt = mydwtsub(R_sub);
            
            % 3. Quantization
            R_quant = round(R_dwt ./ Q_scaled);
            
            % 4. Standard Zig-Zag
            R_zz = zigzag(R_quant);
            
            % 5. Huffman encoding
            Rt_cell{idx} = huffman_encode_block(R_zz);
            idx = idx + 1;
        end
    end
end


function [Rt] = myidwt(Rt_cell, Q_scaled, m, n)
% Huffman decoding + Inverse Zig-Zag + Dequantization + Inverse DWT
    Rt = zeros(m, n);
    idx = 1;
    
    for i = 1:8:m-7
        for j = 1:8:n-7
            % 1. Retrieve and decode block
            block_struct = Rt_cell{idx};
            idx = idx + 1;
            
            R_zz = huffman_decode_block(block_struct);
            
            % 2. Inverse Zig-Zag
            R_izz = izigzag(R_zz);
            
            % 3. Dequantization
            R_dequant = R_izz .* Q_scaled;
            
            % 4. Inverse 2D Haar Wavelet Transform
            Rt(i:i+7, j:j+7) = myidwtsub(R_dequant);
        end
    end
end


function [Rt] = mydwtsub(R)
% Forward 2D Haar Wavelet Transform for an 8x8 block
    Rt = zeros(8, 8);
    
    % Transform along rows
    row_temp = zeros(8, 8);
    for r = 1:8
        row_temp(r, :) = haar1d_forward(R(r, :));
    end
    
    % Transform along columns
    for c = 1:8
        Rt(:, c) = haar1d_forward(row_temp(:, c)');
    end
end


function [Rt] = myidwtsub(R)
% Inverse 2D Haar Wavelet Transform for an 8x8 block
    col_temp = zeros(8, 8);
    
    % Inverse transform along columns
    for c = 1:8
        col_temp(:, c) = haar1d_inverse(R(:, c)');
    end
    
    % Inverse transform along rows
    Rt = zeros(8, 8);
    for r = 1:8
        Rt(r, :) = haar1d_inverse(col_temp(r, :));
    end
end


function out = haar1d_forward(in)
% 1D Haar forward transform on a 1x8 vector
    out = zeros(1, 8);
    half = 4;
    for i = 1:half
        out(i) = (in(2*i-1) + in(2*i)) / sqrt(2);
        out(half + i) = (in(2*i-1) - in(2*i)) / sqrt(2);
    end
end


function out = haar1d_inverse(in)
% 1D Haar inverse transform on a 1x8 vector
    out = zeros(1, 8);
    half = 4;
    for i = 1:half
        out(2*i-1) = (in(i) + in(half + i)) / sqrt(2);
        out(2*i)   = (in(i) - in(half + i)) / sqrt(2);
    end
end