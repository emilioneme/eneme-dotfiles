function float_app
    hyprctl dispatch "hl.dsp.exec_cmd('$argv', { float = true, size = {1280, 720} })"
end
