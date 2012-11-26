if [ `uname` = Darwin ]; then                                                    
    alias updatedb='sudo /usr/libexec/locate.updatedb'
    alias flushdns='sudo killall -HUP mDNSResponder'
fi
