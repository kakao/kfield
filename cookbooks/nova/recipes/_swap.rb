# swap을 사용할 경우에 대비해 swap을 적당히 늘려줌.

# ohai report memory as kB
total_memory = node['memory']['total'].split('kB')[0].to_i
swap_size = (total_memory * (node[:nova][:ram_allocation_ratio] - 1)).to_i

cookbook_file '/root/bin/swapfile.sh' do
    source 'swapfile.sh'
    mode 00755
end

execute "setup swapfile #{ swap_size }kb" do
    command "/root/bin/swapfile.sh #{ swap_size }"
end
