name 'nova-resize-autoconfirm-worker'
description 'nova-resize-autoconfirm-worker'
run_list(
    'recipe[nova::resize-autoconfirm]'
)
