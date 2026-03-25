function owi
    set OPEN_WEBUI_DIR $HOME/open-webui
    echo "Starting Open WebUI as daemon..."
    env DATA_DIR=$OPEN_WEBUI_DIR WEBUI_AUTH=False nohup uvx --native-tls --python 3.11 open-webui@latest serve >$OPEN_WEBUI_DIR/open-webui.log 2>&1 &
    set webui_pid $last_pid

    echo "Service started as daemon:"
    echo "  Open WebUI PID: $webui_pid (log: $OPEN_WEBUI_DIR/open-webui.log)"
    echo ""
    echo "To stop service:"
    echo "  kill $webui_pid"
    echo ""
    echo "To monitor logs:"
    echo "  tail -f $OPEN_WEBUI_DIR/open-webui.log"
end
