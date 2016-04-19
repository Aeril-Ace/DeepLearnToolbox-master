function net = cnnff(net, x)
    n = numel(net.layers);
    net.layers{1}.a{1} = x;
    inputmaps = 1;

    for l = 2 : n   %  for each layer
        if strcmp(net.layers{l}.type, 'c')
            %% ����Ǿ��
            %  !!below can probably be handled by insane matrix operations
            for j = 1 : net.layers{l}.outputmaps   %  for each output map
                %  create temp output map
                z = zeros(size(net.layers{l - 1}.a{1}) - [net.layers{l}.kernelsize - 1, net.layers{l}.kernelsize - 1, 0]);
                for i = 1 : inputmaps   %  for each input map
                    %  convolve with corresponding kernel and add to temp output map
                    z = z + convn(net.layers{l - 1}.a{i}, net.layers{l}.k{i}{j}, 'valid');
                end
                %  add bias, pass through nonlinearity
                net.layers{l}.a{j} = sigm(z + net.layers{l}.b{j});
            end
            %  set number of input maps to this layers number of outputmaps
            inputmaps = net.layers{l}.outputmaps;
        elseif strcmp(net.layers{l}.type, 's')
            %%  ����ǲ������ػ���3 5 7
            %����������ۣ�������ȡ�������Ҫ�����������棺
            %��1�������С������ɵĹ���ֵ��������
            %��2���������������ɹ��ƾ�ֵ��ƫ�ơ�
            %һ����˵��mean-pooling�ܼ�С��һ��������ı���ͼ��ı�����Ϣ��
            %max-pooling�ܼ�С�ڶ���������ı���������Ϣ��
            for j = 1 : inputmaps
                % ƽ��ֵ�ػ� matlab��convn�����м���
                
                z = convn(net.layers{l - 1}.a{j}, ones(net.layers{l}.scale) / (net.layers{l}.scale ^ 2), 'valid');
                net.layers{l}.a{j} = z(1 : net.layers{l}.scale : end, 1 : net.layers{l}.scale : end, :);
                
                % ���ֵ�ػ� �������
                %{
                for i3=1 : size(net.layers{l-1}.a{j},3)
                    for ii=1 : size(net.layers{l-1}.a{j},1) / net.layers{l}.scale
                        for jj=1 : size(net.layers{l-1}.a{j},2) / net.layers{l}.scale
                            net.layers{l}.a{j}(ii,jj,i3) = max(max(net.layers{l - 1}.a{j}((ii-1)*net.layers{l}.scale+1:ii*net.layers{l}.scale, (jj-1)*net.layers{l}.scale+1:jj*net.layers{l}.scale)));
                        end
                    end
                end
                %}
            end %for j = 1 : inputmaps
        end %if strcmp(net.layers{l}.type, 'c')
    end %for l = 2 : n   %  for each layer

    %%  concatenate all end layer feature maps into vector
    net.fv = [];
    for j = 1 : numel(net.layers{n}.a) %���һ������������Ķ��ٸ�С����
        sa = size(net.layers{n}.a{j}); % С����ĳ����
        net.fv = [net.fv; reshape(net.layers{n}.a{j}, sa(1) * sa(2), sa(3))];% С������չ������һ�У�Z��������
    end
    %%  feedforward into output perceptrons
    net.o = sigm(net.ffW * net.fv + repmat(net.ffb, 1, size(net.fv, 2)));

end
