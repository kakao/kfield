
template '/root/resize-autoconfirm.sh' do
  source 'resize-autoconfirm.sh.erb'
  mode 00755
end

cron 'resize-autoconfirm' do
  minute '*/10'
  command '/root/resize-autoconfirm.sh'
end
