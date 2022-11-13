if [ -f /etc/motd ]; then
    cmp -s $HOME/.hushlogin /etc/motd
    if [ $? != 0 ]; then
        tee $HOME/.hushlogin < /etc/motd
        echo -n "Press Enter to continue: " && read ans
    fi
fi
